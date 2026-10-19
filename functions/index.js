'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { validMedia, portfolioContribution } = require('./verification_policy');
initializeApp();
const db = getFirestore();
const options = { region: 'europe-west1', maxInstances: 10, invoker: 'public' };
const {requireActiveAccount: uidOf,requireUsableProfile}=require('./account_guard');

function text(v, max = 1000) { return typeof v === 'string' ? v.trim().slice(0, max) : ''; }
function id(v) { if (typeof v !== 'string' || !v || v.length > 200 || v.includes('/')) throw new HttpsError('invalid-argument', 'Geçersiz kayıt.'); return v; }
const key = (...parts) => Buffer.from(JSON.stringify(parts)).toString('base64url');
// Optional portfolio entries are published directly. They never grant tokens or identity badges.
exports.submitSkillEvidence = onCall(options, async r => {
  const uid = await uidOf(r), skillId = id(r.data?.skillId), entryId = id(r.data?.entryId);
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
    requireUsableProfile(user.data());
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
  const uid = await uidOf(r), entryId = id(r.data?.entryId), ref = db.doc(`skillVerifications/${entryId}`);
  const files = await db.runTransaction(async tx => {
    const userRef = db.doc(`users/${uid}`);
    const [entry,user] = await Promise.all([tx.get(ref),tx.get(userRef)]);
    if (!entry.exists || entry.data().ownerId !== uid || entry.data().type !== 'portfolio') throw new HttpsError('permission-denied','Yalnızca kendi çalışmanı silebilirsin.');
    const p = entry.data(); if (p.status === 'deleted') return p.files || [];
    requireUsableProfile(user.data());
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
  const uid = await uidOf(r), entryId = id(r.data?.entryId), reason = text(r.data.reason,500);
  if (reason.length < 10) throw new HttpsError('invalid-argument','Şikâyet nedenini en az 10 karakterle anlat.');
  const entry = await db.doc(`skillVerifications/${entryId}`).get();
  if (!entry.exists || entry.data().status !== 'published') throw new HttpsError('not-found','Çalışma bulunamadı.');
  await db.doc(`contentReports/${key(uid,entryId)}`).set({reporterId:uid,entryId,ownerId:entry.data().ownerId,reason,status:'open',createdAt:FieldValue.serverTimestamp()});
  return {reported:true};
});
// Keep old clients from requesting a manual approval or receiving a misleading badge.
exports.reviewSkillEvidence = onCall(options, async r => { await uidOf(r); throw new HttpsError('failed-precondition','Manuel doğrulama kaldırıldı. Çalışmalar doğrudan portföyde yayımlanır.'); });
exports.endorseTeaching = onCall(options, async r => { await uidOf(r); throw new HttpsError('failed-precondition','Kişi onayı özelliği kaldırıldı. Çalışmalarını portföyünde paylaşabilirsin.'); });
Object.assign(exports, require('./community'));
Object.assign(exports, require('./learning'));

Object.assign(exports,require('./account_deletion'));

const {onDocumentWritten} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {syncTimeout, sweepTimeouts} = require('./mutual_timeout');
exports.syncMutualExchangeTimeout = onDocumentWritten({
  document: 'sessions/{sessionId}', region: 'europe-west1',
  minInstances: 0, maxInstances: 1, memory: '256MiB', retry: true,
}, event => syncTimeout(db, event.params.sessionId));
exports.processMutualExchangeTimeouts = onSchedule({
  schedule: 'every 15 minutes', timeZone: 'Etc/UTC', region: 'europe-west1',
  minInstances: 0, maxInstances: 1, memory: '256MiB', timeoutSeconds: 300,
  retryCount: 3,
}, () => sweepTimeouts(db));
