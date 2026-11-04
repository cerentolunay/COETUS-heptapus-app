'use strict';
const {FieldValue, Timestamp} = require('firebase-admin/firestore');
const HOUR = 60 * 60 * 1000;
function waiting(s) {
  return s?.schemaVersion === 2 && s.funded === true && s.status === 'active' &&
    Array.isArray(s.participants) && s.participants.length === 2 &&
    s.participants[0] !== s.participants[1] &&
    Array.isArray(s.completionVotes) && s.completionVotes.length === 1 &&
    s.participants.includes(s.completionVotes[0]) &&
    Array.isArray(s.cancellationVotes) && s.cancellationVotes.length === 0 &&
    !s.disputedBy && typeof s.completionRequestedAt?.toMillis === 'function';
}
// Re-read the session, so duplicate/out-of-order Firestore events cannot revive a job.
async function syncTimeout(db, id) {
  return db.runTransaction(async tx => {
    const session = await tx.get(db.doc(`sessions/${id}`));
    const s = session.data(), ref = db.doc(`exchangeTimeoutJobs/${id}`);
    if (!waiting(s)) { tx.delete(ref); return; }
    tx.set(ref, {dueAt: Timestamp.fromMillis(s.completionRequestedAt.toMillis() + (s.remindedAt ? 72 : 24) * HOUR)});
  });
}
async function processTimeout(db, id, now = Date.now()) {
  return db.runTransaction(async tx => {
    const ref = db.doc(`sessions/${id}`), job = db.doc(`exchangeTimeoutJobs/${id}`);
    const snapshot = await tx.get(ref), s = snapshot.data();
    if (!waiting(s)) { tx.delete(job); return 'ignored'; }
    const start = s.completionRequestedAt.toMillis(), expire = now >= start + 72 * HOUR;
    if (!expire && (s.remindedAt || now < start + 24 * HOUR)) {
      tx.set(job, {dueAt: Timestamp.fromMillis(start + (s.remindedAt ? 72 : 24) * HOUR)});
      return 'waiting';
    }
    const wallets = expire ? await tx.getAll(...s.participants.map(uid => db.doc(`users/${uid}`))) : [];
    for (const wallet of wallets) {
      const amount = s.deposits?.[wallet.id], w = wallet.data();
      if (!Number.isSafeInteger(amount) || amount < 10 || amount > 70 ||
          !Number.isSafeInteger(w?.credits) || !Number.isSafeInteger(w?.lockedCredits) || w.lockedCredits < amount) {
        throw new Error(`Invalid mutual wallet: ${id}`);
      }
    }
    const stamp = FieldValue.serverTimestamp(), event = expire ? 'expire' : 'remind';
    if (expire) {
      for (const wallet of wallets) {
        const w = wallet.data(), amount = s.deposits[wallet.id];
        tx.update(wallet.ref, {credits: w.credits + amount, lockedCredits: w.lockedCredits - amount, lastExchangeSessionId: id});
      }
      tx.update(ref, {status: 'expired', settledAt: stamp, updatedAt: stamp});
      tx.set(db.doc(`chats/${id}`), {status: 'expired', updatedAt: stamp}, {merge: true});
      tx.delete(job);
    } else {
      tx.update(ref, {remindedAt: stamp, updatedAt: stamp});
      tx.set(job, {dueAt: Timestamp.fromMillis(start + 72 * HOUR)});
    }
    const recipients = expire ? s.participants : s.participants.filter(uid => !s.completionVotes.includes(uid));
    for (const uid of recipients) {
      tx.set(db.doc(`notifications/mutual_${id}_${event}_${uid}`), {
        userId: uid, senderId: 'system', type: 'session_started',
        title: expire ? 'Yanıt süresi doldu' : 'Takas yanıtını bekliyor',
        message: expire ? `Kendi kilitlediğin ${s.deposits[uid]} token hesabına iade edildi. Sessizlik onay veya referans sayılmaz.` : 'Tamamlanma isteğine yanıt verebilirsin. İtiraz yoksa 72 saat sonunda kendi katkılarınız iade edilir.',
        targetRoute: '/exchange-detail', targetId: id, sessionId: id, read: false, createdAt: stamp,
      });
    }
    return event;
  });
}
async function sweepTimeouts(db, now = Date.now()) {
  let processed = 0;
  // Bounded runtime; remaining jobs are picked up by the next scheduled run.
  for (let page = 0; page < 5; page++) {
    const jobs = await db.collection('exchangeTimeoutJobs').where('dueAt', '<=', Timestamp.fromMillis(now)).orderBy('dueAt').limit(100).get();
    if (jobs.empty) break;
    let failures = 0;
    for (const job of jobs.docs) {
      try { await processTimeout(db, job.id, now); processed++; }
      catch (error) { failures++; console.error('Mutual timeout failed', job.id, error.message); }
    }
    if (failures || jobs.size < 100) break;
  }
  return processed;
}
module.exports = {waiting, syncTimeout, processTimeout, sweepTimeouts};
