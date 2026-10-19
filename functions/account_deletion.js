'use strict';
const {getFirestore,FieldValue} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const {getStorage} = require('firebase-admin/storage');
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const functionsV1 = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const db=getFirestore();
const options={region:'europe-west1',maxInstances:5,timeoutSeconds:540,invoker:'public'};

async function deleteQuery(query,recursive=false) {
  for (;;) {
    const snapshot=await query.limit(100).get();
    if(snapshot.empty)return;
    if(recursive){for(const d of snapshot.docs)await db.recursiveDelete(d.ref);}
    else {const batch=db.batch();for(const d of snapshot.docs)batch.delete(d.ref);await batch.commit();}
  }
}
async function removeContribution(ref,counter) {
  const parent=ref.parent.parent;
  await db.runTransaction(async tx=>{
    const [entry,post]=await Promise.all([tx.get(ref),tx.get(parent)]);
    if(!entry.exists)return;
    if(post.exists)tx.update(parent,{[counter]:Math.max(0,Number(post.data()[counter]||0)-1)});
    tx.delete(ref);
  });
}
async function removeContributions(group,field,uid,counter) {
  for (;;) {
    const snapshot=await db.collectionGroup(group).where(field,'==',uid).limit(100).get();
    if(snapshot.empty)return;
    for(const doc of snapshot.docs)await removeContribution(doc.ref,counter);
  }
}
async function anonymizeShared(collection,uid) {
  const query=db.collection(collection).where('participants','array-contains',uid);
  let last;
  for (;;) {
    const snapshot=await (last?query.startAfter(last):query).limit(100).get();
    if(snapshot.empty)return;
    for(const doc of snapshot.docs){
      const data=doc.data(),names={...(data.participantNames||{}),[uid]:'Silinmiş hesap'};
      const patch={participantNames:names,updatedAt:FieldValue.serverTimestamp()};
      if(data.requesterId===uid)patch.requesterName='Silinmiş hesap';
      if(data.receiverId===uid)patch.receiverName='Silinmiş hesap';
      if(collection==='chats'){
        await deleteQuery(doc.ref.collection('messages').where('senderId','==',uid));
        const skills={...(data.participantSkills||{})};delete skills[uid];patch.participantSkills=skills;
        // Shared chat previews may contain a deleted author's private text.
        patch.lastMessage='Bir katılımcının hesabı silindi.';patch.lastSenderId='';
      }
      if(data.status==='pending'||data.status==='requested'||(collection==='sessions'&&!data.funded&&['active','scheduled'].includes(data.status)))patch.status='cancelled';
      await doc.ref.set(patch,{merge:true});
    }
    last=snapshot.docs.at(-1);
  }
}
async function cleanupAccount(uid) {
  const job=db.doc(`accountDeletions/${uid}`);
  if((await job.get()).data()?.status==='completed')return;
  const [wallet,escrows]=await Promise.all([db.doc(`users/${uid}`).get(),db.collection('escrows').where('participants','array-contains',uid).get()]);
  if(Number(wallet.data()?.lockedCredits||0)>0||escrows.docs.some(d=>d.data().status==='locked'))throw new Error('Kilitli oturum sonuçlanana kadar hesap verileri korunuyor.');
  await job.set({status:'processing',updatedAt:FieldValue.serverTimestamp()},{merge:true});
  // Hide parents first so concurrent likes/comments cannot recreate their children.
  for (;;) {
    const posts=await db.collection('communityPosts').where('authorId','==',uid).limit(100).get();
    if(posts.empty)break;
    for(const post of posts.docs){await post.ref.update({status:'deleted'});await db.recursiveDelete(post.ref);}
  }
  await removeContributions('comments','authorId',uid,'commentCount');
  await removeContributions('likes','userId',uid,'likeCount');
  await deleteQuery(db.collection('skillVerifications').where('ownerId','==',uid),true);
  await deleteQuery(db.collection('skillVerifications').where('studentId','==',uid));
  await deleteQuery(db.collection('interestSuggestions').where('ownerId','==',uid));
  for(const field of ['userId','senderId'])await deleteQuery(db.collection('notifications').where(field,'==',uid));
  for(const field of ['reporterId','ownerId'])await deleteQuery(db.collection('contentReports').where(field,'==',uid));
  for(const collection of ['matches','sessions','chats'])await anonymizeShared(collection,uid);
  const bucket=getStorage().bucket();
  for(const folder of ['communityMedia','portfolioMedia','verificationEvidence'])await bucket.deleteFiles({prefix:`${folder}/${uid}/`});
  await db.recursiveDelete(db.doc(`users/${uid}`));
  // Retain the opaque deletion marker: old ID tokens cannot recreate this user.
  await job.set({status:'completed',completedAt:FieldValue.serverTimestamp()},{merge:true});
}
exports.deleteAccount=onCall(options,async request=>{
  if(!request.auth)throw new HttpsError('unauthenticated','Önce giriş yapmalısın.');
  const uid=request.auth.uid,authTime=Number(request.auth.token.auth_time),now=Math.floor(Date.now()/1000);
  if(!Number.isFinite(authTime)||now-authTime>300||authTime>now+30)
    throw new HttpsError('unauthenticated','Hesabını silmek için yeniden giriş yapmalısın.',{reason:'requires-recent-login'});
  if(request.data?.confirm!==true)throw new HttpsError('invalid-argument','Hesap silme onayı gerekli.');
  const job=db.doc(`accountDeletions/${uid}`),userRef=db.doc(`users/${uid}`);
  await db.runTransaction(async tx=>{
    const [existing,user,escrows]=await Promise.all([tx.get(job),tx.get(userRef),tx.get(db.collection('escrows').where('participants','array-contains',uid))]);
    if(existing.exists)return;
    if(Number(user.data()?.lockedCredits||0)>0||escrows.docs.some(d=>d.data().status==='locked'))
      throw new HttpsError('failed-precondition','Kilitli token bulunan oturumlarını tamamlamalı veya karşılıklı iptal etmelisin. Ardından hesabını silebilirsin.');
    tx.create(job,{status:'queued',requestedAt:FieldValue.serverTimestamp()});
    if(user.exists)tx.update(userRef,{accountDeletionPending:true});
  });
  try {await getAuth().deleteUser(uid);}catch(error){
    if(error.code!=='auth/user-not-found')throw new HttpsError('unavailable','Hesap silme başlatıldı ancak tamamlanamadı. Aynı düğmeden yeniden deneyebilirsin.');
  }
  try {await cleanupAccount(uid);return {deleted:true,pendingCleanup:false};}
  catch(error){logger.error('Account cleanup will be retried',{uid,message:error.message});return {deleted:true,pendingCleanup:true};}
});
// Retries are essential if storage/network cleanup fails after the Auth user is gone.
exports.cleanupDeletedAccount=functionsV1.region('europe-west1').runWith({failurePolicy:true,timeoutSeconds:540,memory:'512MB',maxInstances:5}).auth.user().onDelete(async user=>{
  const job=db.doc(`accountDeletions/${user.uid}`);
  if(!(await job.get()).exists)await job.create({status:'queued',requestedAt:FieldValue.serverTimestamp()});
  await cleanupAccount(user.uid);
});
