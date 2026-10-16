'use strict';
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const db = getFirestore(), options = { region: 'europe-west1', maxInstances: 10, invoker: 'public' };
function uidOf(r) {
  if (!r.auth) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.');
  return r.auth.uid;
}
function id(value) {
  if (typeof value !== 'string' || !value || value.length > 200 || value.includes('/'))
    throw new HttpsError('invalid-argument', 'Geçersiz oturum.');
  return value;
}
function credits(doc) {
  if (!doc.exists || !Number.isSafeInteger(doc.data().credits) || doc.data().credits < 0)
    throw new HttpsError('failed-precondition', 'Profil bakiyesi doğrulanamadı.');
  return doc.data().credits;
}
function notification(tx, uid, sender, type, title, message, sessionId) {
  tx.create(db.collection('notifications').doc(), { userId: uid, senderId: sender, type, title, message,
    targetRoute: '/exchange-detail', targetId: sessionId, sessionId, read: false, createdAt: FieldValue.serverTimestamp() });
}
exports.acceptLearningOffer = onCall(options, async r => {
  const uid = uidOf(r), matchId = id(r.data?.matchId);
  return db.runTransaction(async tx => {
    const matchRef = db.doc(`matches/${matchId}`), escrowRef = db.doc(`escrows/${matchId}`);
    const [match, escrow] = await Promise.all([tx.get(matchRef), tx.get(escrowRef)]);
    if (!match.exists) throw new HttpsError('not-found', 'Teklif bulunamadı.');
    const m = match.data();
    if (m.receiverId !== uid || m.requesterId === uid)
      throw new HttpsError('permission-denied', 'Teklifi yalnızca öğretmen kabul edebilir.');
    if (m.status === 'accepted' && escrow.exists) return { sessionId: matchId, alreadyAccepted: true };
    if (m.status !== 'pending') throw new HttpsError('failed-precondition', 'Bu teklif artık beklemede değil.');
    const amount = m.credits;
    if (!Number.isSafeInteger(amount) || amount <= 0 || amount > 10000)
      throw new HttpsError('failed-precondition', 'Oturumun token bedeli geçersiz.');
    const studentRef = db.doc(`users/${id(m.requesterId)}`), teacherRef = db.doc(`users/${uid}`);
    const [student, teacher] = await Promise.all([tx.get(studentRef), tx.get(teacherRef)]);
    const available = credits(student); credits(teacher);
    if (available < amount) throw new HttpsError('failed-precondition', 'Öğrencinin yeterli tokenı yok. Teklif için henüz token kesilmedi.');
    const participants = [m.requesterId, uid].sort(), now = FieldValue.serverTimestamp();
    const names = { [m.requesterId]: student.data().displayName || student.data().name || 'Öğrenci',
      [uid]: teacher.data().displayName || teacher.data().name || 'Öğretmen' };
    tx.update(studentRef, { credits: available - amount, lockedCredits: (student.data().lockedCredits || 0) + amount });
    tx.update(matchRef, { status: 'accepted', sessionId: matchId, chatId: matchId, updatedAt: now });
    tx.set(db.doc(`sessions/${matchId}`), { id: matchId, matchId, teacherId: uid, studentId: m.requesterId,
      participants, skill: m.skillName, credits: amount, status: 'active', funded: true, refundVotes: [],
      createdAt: now, updatedAt: now });
    tx.create(escrowRef, { participants, studentId: m.requesterId, teacherId: uid, credits: amount,
      sessionId: matchId, status: 'locked', createdAt: now, updatedAt: now });
    tx.set(db.doc(`chats/${matchId}`), { id: matchId, participants, participantNames: names, sessionId: matchId,
      matchId, skillName: m.skillName, credits: amount, status: 'active', updatedAt: now }, { merge: true });
    tx.create(db.doc(`transactions/learning_lock_${matchId}`), { fromUserId: m.requesterId, toUserId: 'escrow',
      amount, sessionId: matchId, type: 'learning_lock', createdAt: now });
    notification(tx, m.requesterId, uid, 'offer_accepted', 'Teklif kabul edildi',
      `${amount} token oturum için kilitlendi. Tamamladığında öğretmene aktarılacak.`, matchId);
    return { sessionId: matchId, alreadyAccepted: false };
  });
});
exports.completeLearningSession = onCall(options, async r => {
  const uid = uidOf(r), sessionId = id(r.data?.sessionId);
  return db.runTransaction(async tx => {
    const sessionRef = db.doc(`sessions/${sessionId}`), escrowRef = db.doc(`escrows/${sessionId}`);
    const [session, escrow] = await Promise.all([tx.get(sessionRef), tx.get(escrowRef)]);
    if (!session.exists || !escrow.exists) throw new HttpsError('failed-precondition', 'Bu oturum için kilitlenmiş token bulunmuyor.');
    const s = session.data(), e = escrow.data();
    if (s.studentId !== uid) throw new HttpsError('permission-denied', 'Tamamlandığını yalnızca öğrenci onaylayabilir.');
    if (e.status === 'completed') return { completed: true, alreadyProcessed: true };
    if (e.status !== 'locked' || s.status !== 'active' || e.studentId !== uid || e.teacherId !== s.teacherId)
      throw new HttpsError('failed-precondition', 'Oturum tamamlamaya uygun değil.');
    const studentRef = db.doc(`users/${uid}`), teacherRef = db.doc(`users/${s.teacherId}`);
    const [student, teacher] = await Promise.all([tx.get(studentRef), tx.get(teacherRef)]);
    credits(student); const available = credits(teacher);
    if ((student.data().lockedCredits || 0) < e.credits || !Number.isSafeInteger(available + e.credits))
      throw new HttpsError('failed-precondition', 'Kilitli bakiye doğrulanamadı.');
    const now = FieldValue.serverTimestamp();
    tx.update(studentRef, { lockedCredits: student.data().lockedCredits - e.credits });
    tx.update(teacherRef, { credits: available + e.credits });
    tx.update(sessionRef, { status: 'completed', updatedAt: now });
    tx.update(escrowRef, { status: 'completed', updatedAt: now });
    tx.set(db.doc(`chats/${sessionId}`), { status: 'completed', updatedAt: now }, { merge: true });
    tx.create(db.doc(`transactions/learning_payment_${sessionId}`), { fromUserId: uid, toUserId: s.teacherId,
      amount: e.credits, type: 'learning_payment', sessionId, createdAt: now });
    notification(tx, s.teacherId, uid, 'learning_completed', 'Oturum tamamlandı', `${e.credits} token hesabına aktarıldı.`, sessionId);
    return { completed: true, alreadyProcessed: false };
  });
});
exports.cancelLearningSession = onCall(options, async r => {
  const uid = uidOf(r), sessionId = id(r.data?.sessionId);
  return db.runTransaction(async tx => {
    const sessionRef = db.doc(`sessions/${sessionId}`), escrowRef = db.doc(`escrows/${sessionId}`);
    const [session, escrow] = await Promise.all([tx.get(sessionRef), tx.get(escrowRef)]);
    if (!session.exists || !escrow.exists) throw new HttpsError('not-found', 'Kilitli oturum bulunamadı.');
    const s = session.data(), e = escrow.data();
    if (![s.teacherId, s.studentId].includes(uid)) throw new HttpsError('permission-denied', 'Bu oturuma erişimin yok.');
    if (e.status === 'refunded') return { refunded: true };
    if (e.status !== 'locked' || s.status !== 'active') throw new HttpsError('failed-precondition', 'Bu oturum iptal edilemez.');
    const votes = [...new Set([...(s.refundVotes || []), uid])];
    const agreed = votes.includes(s.teacherId) && votes.includes(s.studentId);
    const studentRef = db.doc(`users/${s.studentId}`);
    const student = agreed ? await tx.get(studentRef) : null;
    if (agreed && (credits(student) < 0 || (student.data().lockedCredits || 0) < e.credits))
      throw new HttpsError('failed-precondition', 'Kilitli bakiye doğrulanamadı.');
    const now = FieldValue.serverTimestamp();
    tx.update(sessionRef, { refundVotes: votes, ...(agreed ? { status: 'cancelled' } : {}), updatedAt: now });
    if (agreed) {
      tx.update(studentRef, { credits: student.data().credits + e.credits, lockedCredits: student.data().lockedCredits - e.credits });
      tx.update(escrowRef, { status: 'refunded', updatedAt: now });
      tx.set(db.doc(`chats/${sessionId}`), { status: 'cancelled', updatedAt: now }, { merge: true });
      tx.create(db.doc(`transactions/learning_refund_${sessionId}`), { fromUserId: 'escrow', toUserId: s.studentId,
        amount: e.credits, type: 'learning_refund', sessionId, createdAt: now });
    }
    if (!(s.refundVotes || []).includes(uid)) notification(tx, uid === s.studentId ? s.teacherId : s.studentId,
      uid, 'learning_refund', agreed ? 'Oturum iptal edildi' : 'Oturum için iptal isteği',
      agreed ? `${e.credits} token öğrenciye iade edildi.` : 'İki taraf onayladığında kilitli token öğrenciye iade edilir.', sessionId);
    return { refunded: agreed };
  });
});
