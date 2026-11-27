'use strict';
const {FieldValue, Timestamp} = require('firebase-admin/firestore');
const HOUR = 60 * 60 * 1000;
function disputed(s) {
  return s?.schemaVersion === 2 && s.funded === true && s.status === 'disputed' &&
    Array.isArray(s.participants) && s.participants.length === 2 &&
    s.participants[0] !== s.participants[1] && s.participants.includes(s.disputedBy);
}
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
async function syncTimeout(db, id, disputeTime) {
  return db.runTransaction(async tx => {
    const session = await tx.get(db.doc(`sessions/${id}`));
    const s = session.data(), ref = db.doc(`exchangeTimeoutJobs/${id}`);
    if (disputed(s)) {
      // Only the server can write this immutable dispute clock. The event time
      // preserves the first objection even if a cancellation vote follows it.
      const candidate = disputeTime || s.updatedAt;
      const start = s.disputeOpenedAt && (!candidate || s.disputeOpenedAt.toMillis() <= candidate.toMillis())
        ? s.disputeOpenedAt : candidate;
      if (typeof start?.toMillis !== 'function') throw new Error(`Missing dispute clock: ${id}`);
      if (!s.disputeOpenedAt || start.toMillis() < s.disputeOpenedAt.toMillis()) tx.update(session.ref, {disputeOpenedAt: start});
      tx.set(ref, {dueAt: Timestamp.fromMillis(start.toMillis() + 24 * HOUR)});
      return;
    }
    if (!waiting(s)) { tx.delete(ref); return; }
    tx.set(ref, {dueAt: Timestamp.fromMillis(s.completionRequestedAt.toMillis() + (s.remindedAt ? 72 : 24) * HOUR)});
  });
}
async function processTimeout(db, id, now = Date.now()) {
  return db.runTransaction(async tx => {
    const ref = db.doc(`sessions/${id}`), job = db.doc(`exchangeTimeoutJobs/${id}`);
    const snapshot = await tx.get(ref), s = snapshot.data();
    const dispute = disputed(s);
    if (!waiting(s) && !dispute) { tx.delete(job); return 'ignored'; }
    const clock = dispute ? s.disputeOpenedAt : s.completionRequestedAt;
    if (typeof clock?.toMillis !== 'function') throw new Error(`Missing timeout clock: ${id}`);
    const start = clock.toMillis(), expire = now >= start + (dispute ? 24 : 72) * HOUR;
    if (!expire && (dispute || s.remindedAt || now < start + 24 * HOUR)) {
      tx.set(job, {dueAt: Timestamp.fromMillis(start + (dispute || !s.remindedAt ? 24 : 72) * HOUR)});
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
    const stamp = FieldValue.serverTimestamp(), event = expire ? (dispute ? 'dispute_closed' : 'expire') : 'remind';
    if (expire) {
      for (const wallet of wallets) {
        const w = wallet.data(), amount = s.deposits[wallet.id];
        tx.update(wallet.ref, {credits: w.credits + amount, lockedCredits: w.lockedCredits - amount, lastExchangeSessionId: id});
      }
      const status = dispute ? 'dispute_closed' : 'expired';
      tx.update(ref, {status, settledAt: stamp, updatedAt: stamp});
      tx.set(db.doc(`chats/${id}`), {status, updatedAt: stamp}, {merge: true});
      tx.delete(job);
    } else {
      tx.update(ref, {remindedAt: stamp, updatedAt: stamp});
      tx.set(job, {dueAt: Timestamp.fromMillis(start + 72 * HOUR)});
    }
    const recipients = expire ? s.participants : s.participants.filter(uid => !s.completionVotes.includes(uid));
    for (const uid of recipients) {
      tx.set(db.doc(`notifications/mutual_${id}_${event}_${uid}`), {
        userId: uid, senderId: 'system', type: 'session_started',
        title: dispute ? 'Anlaşmazlıkla kapandı' : expire ? 'Yanıt süresi doldu' : 'Takas yanıtını bekliyor',
        message: dispute ? `24 saatlik uzlaşma süresi doldu. Kendi kilitlediğin ${s.deposits[uid]} token iade edildi. Takas başarılı sayılmaz; bu sonuç haklılık kararı değildir.` : expire ? `Kendi kilitlediğin ${s.deposits[uid]} token hesabına iade edildi. Sessizlik onay veya referans sayılmaz.` : 'Tamamlanma isteğine yanıt verebilirsin. İtiraz yoksa 72 saat sonunda kendi katkılarınız iade edilir.',
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
module.exports = {waiting, disputed, syncTimeout, processTimeout, sweepTimeouts};
