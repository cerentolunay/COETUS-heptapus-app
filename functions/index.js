'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { approvalEffect, canEndorse, validMedia, portfolioContribution } = require('./verification_policy');
initializeApp();
const db = getFirestore();
const options = { region: 'europe-west1', maxInstances: 10, invoker: 'public' };
function uidOf(r) { if (!r.auth) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.'); return r.auth.uid; }
function text(v, max = 1000) { return typeof v === 'string' ? v.trim().slice(0, max) : ''; }
function id(v) { if (typeof v !== 'string' || !v || v.length > 200 || v.includes('/')) throw new HttpsError('invalid-argument', 'Geçersiz kayıt.'); return v; }
const key = (...parts) => Buffer.from(JSON.stringify(parts)).toString('base64url');
// Optional portfolio entries are published directly. They never grant tokens or identity badges.
exports.submitSkillEvidence = onCall(options, async r => {
  const uid = uidOf(r), skillId = id(r.data?.skillId), entryId = id(r.data?.entryId);
  const description = text(r.data.description), paths = r.data.paths;
  if (description.length < 10 || !Array.isArray(paths) || paths.length > 3)
    throw new HttpsError('invalid-argument', 'Çalışmanı en az 10 karakterle anlat. En fazla 3 dosya ekleyebilirsin.');
  const files = [];
  for (const path of paths) {
    const parts = typeof path === 'string' ? path.split('/') : [];
    if (parts.length !== 4 || parts[0] !== 'portfolioMedia' || parts[1] !== uid || parts[2] !== entryId || !/^[A-Za-z0-9_.-]+$/.test(parts[3]))
      throw new HttpsError('permission-denied', 'Çalışma dosyası sana ait değil.');
    let meta;
    try { [meta] = await getStorage().bucket().file(path).getMetadata(); } catch { throw new HttpsError('not-found', 'Çalışma dosyası bulunamadı.'); }
    if (!validMedia(meta.contentType, Number(meta.size))) throw new HttpsError('invalid-argument', 'Dosya türü veya boyutu uygun değil.');
    files.push({ path, contentType: meta.contentType, size: Number(meta.size) });
  }
  return db.runTransaction(async tx => {
    const ref = db.doc(`skillVerifications/${entryId}`), userRef = db.doc(`users/${uid}`), skillRef = userRef.collection('teachSkills').doc(skillId);
    const [old, user, skill] = await Promise.all([tx.get(ref), tx.get(userRef), tx.get(skillRef)]);
    if (old.exists) {
      const p = old.data();
      if (p.ownerId === uid && p.skillId === skillId && p.description === description && p.status === 'published' && JSON.stringify(p.files.map(f=>f.path)) === JSON.stringify(paths)) return { id: entryId };
      throw new HttpsError('already-exists', 'Çalışma kaydı zaten kullanılmış.');
    }
    if (!user.exists || !skill.exists) throw new HttpsError('not-found', 'Önce yeteneğini profiline ekle.');
    const counts = {...(user.data().portfolioSkillCounts || {})}, countKey = key(skillId);
    const before = portfolioContribution(counts);
    if (files.length) counts[countKey] = (counts[countKey] || 0) + 1;
    tx.create(ref, {ownerId: uid, ownerName: user.data().displayName || user.data().name || 'Kullanıcı', skillId,
      skillName: skill.data().name, skillLevel: skill.data().level, description, files, type:'portfolio', status:'published', reward:0, createdAt:FieldValue.serverTimestamp()});
    tx.update(userRef, {portfolioSkillCounts: counts, portfolioTrust: portfolioContribution(counts),
      trustScore: Math.min(100, (user.data().trustScore || 0) + portfolioContribution(counts) - before)});
    return {id:entryId};
  });
});
exports.deletePortfolioEntry = onCall(options, async r => {
  const uid = uidOf(r), entryId = id(r.data?.entryId), ref = db.doc(`skillVerifications/${entryId}`);
  const files = await db.runTransaction(async tx => {
    const userRef = db.doc(`users/${uid}`);
    const [entry,user] = await Promise.all([tx.get(ref),tx.get(userRef)]);
    if (!entry.exists || entry.data().ownerId !== uid || entry.data().type !== 'portfolio') throw new HttpsError('permission-denied','Yalnızca kendi çalışmanı silebilirsin.');
    const p = entry.data(); if (p.status === 'deleted') return p.files || [];
    const counts = {...(user.data().portfolioSkillCounts || {})}, countKey = key(p.skillId), before = portfolioContribution(counts);
    if (p.files.length) counts[countKey] = Math.max(0,(counts[countKey] || 0)-1);
    tx.update(ref,{status:'deleted',deletedAt:FieldValue.serverTimestamp()});
    tx.update(userRef,{portfolioSkillCounts:counts,portfolioTrust:portfolioContribution(counts),trustScore:Math.max(0,(user.data().trustScore || 0)+portfolioContribution(counts)-before)});
    return p.files;
  });
  for (const file of files) await getStorage().bucket().file(file.path).delete({ignoreNotFound:true});
  return {deleted:true};
});
exports.reportPortfolioEntry = onCall(options, async r => {
  const uid = uidOf(r), entryId = id(r.data?.entryId), reason = text(r.data.reason,500);
  if (reason.length < 10) throw new HttpsError('invalid-argument','Şikâyet nedenini en az 10 karakterle anlat.');
  const entry = await db.doc(`skillVerifications/${entryId}`).get();
  if (!entry.exists || entry.data().status !== 'published') throw new HttpsError('not-found','Çalışma bulunamadı.');
  await db.doc(`contentReports/${key(uid,entryId)}`).set({reporterId:uid,entryId,ownerId:entry.data().ownerId,reason,status:'open',createdAt:FieldValue.serverTimestamp()});
  return {reported:true};
});
// Keep old clients from requesting a manual approval or receiving a misleading badge.
exports.reviewSkillEvidence = onCall(options, async r => { uidOf(r); throw new HttpsError('failed-precondition','Manuel doğrulama kaldırıldı. Çalışmalar doğrudan portföyde yayımlanır.'); });
exports.endorseTeaching = onCall(options, async r => {
  const uid = uidOf(r), sessionId = id(r.data?.sessionId), skillId = id(r.data?.skillId), comment = text(r.data.comment,500);
  if (comment.length < 10) throw new HttpsError('invalid-argument','Deneyimini en az 10 karakterle anlat.');
  return db.runTransaction(async tx => {
    const session = await tx.get(db.doc(`sessions/${sessionId}`));
    if (!session.exists) throw new HttpsError('not-found','Oturum bulunamadı.');
    const s = session.data(), ref = db.doc(`skillVerifications/peer_${key(s.teacherId,skillId,uid)}`);
    const ownerRef = db.doc(`users/${id(s.teacherId)}`), skillRef = ownerRef.collection('teachSkills').doc(skillId), rewardRef = ownerRef.collection('verificationRewards').doc(skillId);
    const [match,skill,existing,person,owner,reward] = await Promise.all([tx.get(db.doc(`matches/${id(s.matchId)}`)),tx.get(skillRef),tx.get(ref),tx.get(db.doc(`users/${uid}`)),tx.get(ownerRef),tx.get(rewardRef)]);
    if (!match.exists || !skill.exists || !owner.exists || !canEndorse(s,match.data(),uid,skill.data())) throw new HttpsError('permission-denied','Yalnızca tamamlanan gerçek eşleşmendeki yeteneği onaylayabilirsin.');
    if (existing.exists) throw new HttpsError('already-exists','Bu kişinin bu yeteneğini zaten onayladın.');
    const effect = approvalEffect(owner.data(),reward.exists), now = FieldValue.serverTimestamp();
    tx.create(ref,{ownerId:s.teacherId,skillId,skillName:skill.data().name,skillLevel:skill.data().level,type:'peer',status:'approved',sessionId,
      studentId:uid,studentName:person.data()?.displayName || person.data()?.name || 'Eşleştiği kişi',description:comment,files:[],reward:effect.reward,createdAt:now});
    // A peer endorsement is not identity verification: never set users.verified here.
    tx.update(ownerRef,{credits:effect.credits,trustScore:effect.trustScore,verificationCount:effect.verificationCount,peerApprovalCount:effect.peerApprovalCount});
    tx.update(skillRef,{verifiedName:skill.data().name,verifiedLevel:skill.data().level,peerApprovalCount: (skill.data().peerApprovalCount || 0)+1});
    if (!reward.exists) {
      tx.create(rewardRef,{verificationId:ref.id,amount:effect.reward,createdAt:now});
      if (effect.reward) tx.create(db.doc(`transactions/verification_${key(s.teacherId,skillId)}`),{fromUserId:'system',toUserId:s.teacherId,amount:effect.reward,type:'peer_reward',verificationId:ref.id,createdAt:now});
    }
    tx.create(db.collection('notifications').doc(),{userId:s.teacherId,senderId:uid,type:'verification_approved',title:'Eşleştiğin kişi yeteneğini onayladı',message:`${skill.data().name} için yeni onay aldın.${effect.reward ? ` ${effect.reward} token kazandın!` : ''}`,targetRoute:'/verification',targetId:ref.id,read:false,createdAt:now});
    return effect;
  });
});
Object.assign(exports, require('./community'));
Object.assign(exports, require('./learning'));
