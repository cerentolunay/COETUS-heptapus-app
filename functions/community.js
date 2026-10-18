'use strict';
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { validMedia } = require('./verification_policy');
const db = getFirestore();
const options = { region: 'europe-west1', maxInstances: 10, invoker: 'public' };
const {requireActiveAccount: uidOf,requireUsableProfile}=require('./account_guard');

function id(value) {
  if (typeof value !== 'string' || !value || value.length > 200 || value.includes('/'))
    throw new HttpsError('invalid-argument', 'Geçersiz kayıt.');
  return value;
}
function body(value, max) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max)
    throw new HttpsError('invalid-argument', `Metin 1–${max} karakter olmalı.`);
  return value.trim();
}
const key = (...parts) => Buffer.from(JSON.stringify(parts)).toString('base64url');
function published(snapshot) {
  if (!snapshot.exists || snapshot.data().status !== 'published')
    throw new HttpsError('not-found', 'Paylaşım artık yayında değil.');
  return snapshot.data();
}
function balance(user) {
  requireUsableProfile(user);
  const credits = user?.credits ?? 0;
  if (!Number.isSafeInteger(credits) || credits < 0)
    throw new HttpsError('failed-precondition', 'Token bakiyesi doğrulanamadı.');
  return credits;
}
function notify(tx, userId, senderId, type, title, message, postId) {
  if (userId === senderId) return;
  tx.create(db.collection('notifications').doc(), { userId, senderId, type, title, message,
    targetRoute: '/community-post', targetId: postId, read: false, createdAt: FieldValue.serverTimestamp() });
}
exports.publishCommunityPost = onCall(options, async r => {
  const uid = await uidOf(r), postId = id(r.data?.postId), skillId = id(r.data?.skillId);
  const caption = body(r.data.caption, 2000);
  let media = null;
  if (r.data.mediaPath) {
    const path = r.data.mediaPath;
    const parts = typeof path === 'string' ? path.split('/') : [];
    if (parts.length !== 4 || parts[0] !== 'communityMedia' || parts[1] !== uid || parts[2] !== postId ||
        !/^[A-Za-z0-9_.-]+$/.test(parts[3]))
      throw new HttpsError('permission-denied', 'Bu paylaşım için seçtiğin dosyayı yeniden yükle.');
    let meta;
    try { [meta] = await getStorage().bucket().file(path).getMetadata(); }
    catch { throw new HttpsError('not-found', 'Paylaşım dosyası bulunamadı.'); }
    if (!validMedia(meta.contentType, Number(meta.size)))
      throw new HttpsError('invalid-argument', 'Fotoğraf en fazla 10 MB, video 50 MB olabilir.');
    media = { path, contentType: meta.contentType, size: Number(meta.size) };
  }
  return db.runTransaction(async tx => {
    const ref = db.doc(`communityPosts/${postId}`);
    const [existing, skill, user] = await Promise.all([tx.get(ref),
      tx.get(db.doc(`users/${uid}/teachSkills/${skillId}`)), tx.get(db.doc(`users/${uid}`))]);
    if (existing.exists) {
      const old = existing.data();
      if (old.authorId === uid && old.skillId === skillId && old.caption === caption &&
          (old.media?.path ?? null) === (media?.path ?? null) && old.status === 'published') return { postId };
      throw new HttpsError('already-exists', 'Bu paylaşım kaydı zaten kullanılmış.');
    }
    if (!skill.exists || !user.exists) throw new HttpsError('failed-precondition', 'Önce öğrettiğin yeteneği profiline ekle.');
    requireUsableProfile(user.data());
    tx.create(ref, { authorId: uid, authorName: user.data().displayName || user.data().name || 'Kullanıcı',
      authorPhotoUrl: user.data().photoUrl || '', skillId, skillName: skill.data().name, caption, media,
      status: 'published', likeCount: 0, commentCount: 0, supportTotal: 0, createdAt: FieldValue.serverTimestamp() });
    return { postId };
  });
});
exports.setCommunityLike = onCall(options, async r => {
  const uid = await uidOf(r), postId = id(r.data?.postId);
  if (typeof r.data.liked !== 'boolean') throw new HttpsError('invalid-argument', 'Beğeni durumu gerekli.');
  return db.runTransaction(async tx => {
    const ref = db.doc(`communityPosts/${postId}`), like = ref.collection('likes').doc(uid);
    const [post, previous, actor] = await Promise.all([tx.get(ref), tx.get(like), tx.get(db.doc(`users/${uid}`))]);
    requireUsableProfile(actor.data());
    const p = published(post);
    if (previous.exists === r.data.liked) return { liked: previous.exists };
    if (r.data.liked) tx.create(like, { userId: uid, createdAt: FieldValue.serverTimestamp() });
    else tx.delete(like);
    tx.update(ref, { likeCount: Math.max(0, p.likeCount + (r.data.liked ? 1 : -1)) });
    return { liked: r.data.liked };
  });
});
exports.addCommunityComment = onCall(options, async r => {
  const uid = await uidOf(r), postId = id(r.data?.postId), commentId = id(r.data?.commentId), text = body(r.data.text, 500);
  return db.runTransaction(async tx => {
    const ref = db.doc(`communityPosts/${postId}`), comment = ref.collection('comments').doc(commentId);
    const [post, previous, user] = await Promise.all([tx.get(ref), tx.get(comment), tx.get(db.doc(`users/${uid}`))]);
    const p = published(post);
    if (previous.exists) {
      if (previous.data().authorId === uid && previous.data().text === text) return { commentId };
      throw new HttpsError('already-exists', 'Yorum kaydı zaten kullanılmış.');
    }
    if (!user.exists) throw new HttpsError('failed-precondition', 'Önce profilini tamamla.');
    requireUsableProfile(user.data());
    tx.create(comment, { authorId: uid, authorName: user.data().displayName || user.data().name || 'Kullanıcı',
      text, createdAt: FieldValue.serverTimestamp() });
    tx.update(ref, { commentCount: p.commentCount + 1 });
    notify(tx, p.authorId, uid, 'community_activity', 'Paylaşımına yeni yorum', text, postId);
    return { commentId };
  });
});
exports.supportCommunityPost = onCall(options, async r => {
  const uid = await uidOf(r), postId = id(r.data?.postId), requestId = id(r.data?.requestId), amount = r.data.amount;
  if (!Number.isSafeInteger(amount) || amount < 1 || amount > 100)
    throw new HttpsError('invalid-argument', 'Destek miktarı 1–100 token olmalı.');
  return db.runTransaction(async tx => {
    const transfer = db.doc(`transactions/tip_${key(uid, requestId)}`);
    const old = await tx.get(transfer);
    if (old.exists) {
      if (old.data().postId !== postId || old.data().amount !== amount)
        throw new HttpsError('already-exists', 'Bu destek isteği farklı bir işlem için kullanılmış.');
      return { amount, alreadyProcessed: true };
    }
    const postRef = db.doc(`communityPosts/${postId}`);
    const post = await tx.get(postRef), p = published(post);
    if (p.authorId === uid) throw new HttpsError('failed-precondition', 'Kendi paylaşımına token gönderemezsin.');
    const senderRef = db.doc(`users/${uid}`), receiverRef = db.doc(`users/${p.authorId}`);
    const [sender, receiver] = await Promise.all([tx.get(senderRef), tx.get(receiverRef)]);
    if (!sender.exists || !receiver.exists) throw new HttpsError('not-found', 'Profil bulunamadı.');
    const available = balance(sender.data()), receiving = balance(receiver.data());
    if (available < amount) throw new HttpsError('failed-precondition', 'Yeterli tokenın yok. Kalp ve yorum bırakmak ücretsiz.');
    if (!Number.isSafeInteger(receiving + amount)) throw new HttpsError('failed-precondition', 'Alıcının bakiyesi güncellenemedi.');
    tx.update(senderRef, { credits: available - amount });
    tx.update(receiverRef, { credits: receiving + amount });
    tx.update(postRef, { supportTotal: p.supportTotal + amount });
    tx.create(transfer, { fromUserId: uid, toUserId: p.authorId, amount, type: 'community_support', postId,
      createdAt: FieldValue.serverTimestamp() });
    notify(tx, p.authorId, uid, 'token_support', 'Paylaşımına token desteği', `${amount} token destek aldın.`, postId);
    return { amount, alreadyProcessed: false };
  });
});
exports.deleteCommunityPost = onCall(options, async r => {
  const uid = await uidOf(r), ref = db.doc(`communityPosts/${id(r.data?.postId)}`);
  const path = await db.runTransaction(async tx => {
    const doc = await tx.get(ref);
    if (!doc.exists || doc.data().authorId !== uid) throw new HttpsError('permission-denied', 'Yalnızca kendi paylaşımını kaldırabilirsin.');
    tx.update(ref, { status: 'deleted', deletedAt: FieldValue.serverTimestamp() });
    return doc.data().media?.path;
  });
  if (path) await getStorage().bucket().file(path).delete({ ignoreNotFound: true });
  return { deleted: true };
});
