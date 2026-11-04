const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, writeBatch, collection, query, where, getDocs } = require('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');
const enabled = !!process.env.FIRESTORE_EMULATOR_HOST;
let env, db, api, bucket;
before(async () => {
  if (!enabled) return;
  process.env.GCLOUD_PROJECT = 'demo-coetus';
  process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: 'demo-coetus', storageBucket: 'demo-coetus.appspot.com' });
  env = await initializeTestEnvironment({ projectId: 'demo-coetus',
    firestore: { rules: fs.readFileSync(require('node:path').join(__dirname, '../firestore.rules'), 'utf8') },
    storage: { rules: fs.readFileSync(require('node:path').join(__dirname, '../storage.rules'), 'utf8') } });
  api = require('./index');
  db = require('firebase-admin/firestore').getFirestore();
  bucket = require('firebase-admin/storage').getStorage().bucket();
});
beforeEach(async () => { if (enabled) { await env.clearFirestore(); await env.clearStorage(); if(process.env.FIREBASE_AUTH_EMULATOR_HOST) await fetch('http://'+process.env.FIREBASE_AUTH_EMULATOR_HOST+'/emulator/v1/projects/demo-coetus/accounts',{method:'DELETE'}); } });
after(async () => {
  if (enabled) {
    if (env) await env.cleanup();
    if (require('firebase-admin/app').getApps().length) await require('firebase-admin/app').deleteApp(require('firebase-admin/app').getApp());
  }
});
const emulatorTest = (name, fn) => test(name, { skip: !enabled }, fn);
async function seed() {
  await db.doc('users/teacher').set({ id: 'teacher', email: 'teacher@example.test', credits: 0, trustScore: 0, verified: false });
  await db.doc('users/teacher/teachSkills/guitar').set({ id: 'guitar', name: 'Gitar', level: 5 });
  for (const student of ['student', 'student2']) {
    await db.doc(`users/${student}`).set({ id: student, displayName: student, email: `${student}@example.test` });
    await db.doc(`matches/${student}`).set({ requesterId: student, receiverId: 'teacher', status: 'accepted',
      participants: [student, 'teacher'], skillName: 'Gitar', credits: 30 });
    await db.doc(`sessions/${student}`).set({ teacherId: 'teacher', studentId: student, matchId: student,
      skill: 'Gitar', status: 'completed', funded: true, credits: 30 });
  }
}
const request = (uid, data, reviewer = false) => ({ auth: { uid, token: { verificationReviewer: reviewer } }, data });
async function directClaim(uid, name) {
  const {runTransaction,serverTimestamp}=require('firebase/firestore');
  const client=env.authenticatedContext(uid).firestore();
  return runTransaction(client,async tx=>{
    const user=doc(client,`users/${uid}`),target=doc(client,`usernames/${name}`);
    const profile=await tx.get(user),claimed=await tx.get(target);
    if(claimed.exists()&&claimed.data().userId!==uid)throw new Error('already-exists');
    const old=profile.data().username;
    if(old&&old!==name)tx.update(doc(client,`usernames/${old}`),{active:false,updatedAt:serverTimestamp()});
    tx.set(target,{userId:uid,active:true,updatedAt:serverTimestamp()});
    tx.update(user,{username:name,usernameChangedAt:serverTimestamp()});
  });
}
emulatorTest('direct username transactions reserve one owner and reject stolen or unpaired aliases',async()=>{
  await seed();
  const results=await Promise.allSettled(['student','teacher'].map(uid=>directClaim(uid,'ipek_01')));
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  const owner=(await db.doc('usernames/ipek_01').get()).data().userId;
  const other=owner==='student'?'teacher':'student';
  await directClaim(owner,'yeni_ad');
  assert.equal((await db.doc('usernames/ipek_01').get()).data().active,false);
  await assert.rejects(directClaim(other,'ipek_01'));
  const client=env.authenticatedContext(other).firestore();
  await assertFails(updateDoc(doc(client,`users/${other}`),{username:'forged'}));
  await assertFails(setDoc(doc(client,'usernames/forged'),{userId:other,active:true}));
  await assertFails(directClaim(other,'admin'));
  await assertFails(directClaim(other,'PYTHON'));
  await assertFails(directClaim(other,'müzik'));
  await assertSucceeds(getDoc(doc(client,'usernames/yeni_ad')));
  await assertFails(getDocs(collection(client,'usernames')));
  await db.doc('accountDeletions/'+other).set({status:'pending'});
  await assertFails(directClaim(other,'deleted_name'));
});
emulatorTest('direct username changes cannot alter balances, verification or another reservation',async()=>{
  const {serverTimestamp}=require('firebase/firestore'); await seed();
  await directClaim('student','deniz');await directClaim('teacher','ece');
  const client=env.authenticatedContext('student').firestore();
  const batch=writeBatch(client);
  batch.set(doc(client,'usernames/stolen'),{userId:'student',active:true,updatedAt:serverTimestamp()});
  batch.update(doc(client,'users/student'),{username:'stolen',usernameChangedAt:serverTimestamp(),credits:999});
  await assertFails(batch.commit());
  await assertFails(updateDoc(doc(client,'usernames/ece'),{active:false,updatedAt:serverTimestamp()}));
  const orphan=writeBatch(client);
  orphan.set(doc(client,'usernames/next_name'),{userId:'student',active:true,updatedAt:serverTimestamp()});
  orphan.update(doc(client,'users/student'),{username:'next_name',usernameChangedAt:serverTimestamp()});
  await assertFails(orphan.commit());
});
async function directConnect(uid,other) {
  const {serverTimestamp,runTransaction}=require('firebase/firestore');
  const client=env.authenticatedContext(uid).firestore(),participants=[uid,other].sort();
  const id='face_'+Buffer.from(JSON.stringify(participants)).toString('base64url');
  return runTransaction(client,async tx=>{
    const connection=doc(client,`profileConnections/${id}`),chat=doc(client,`chats/${id}`);
    const existing=await tx.get(connection),existingChat=await tx.get(chat);
    const votes=existing.data()?.confirmedBy||[];
    if(!votes.includes(uid)){
      votes.push(uid);tx.set(connection,{participants,confirmedBy:votes,status:votes.length===2?'confirmed':'pending',...(!existing.exists()?{createdAt:serverTimestamp()}:{}),updatedAt:serverTimestamp()},{merge:true});
    }
    if(votes.length===2&&!existingChat.exists())tx.set(chat,{id,participants,participantNames:{},kind:'in_person',credits:0,status:'active',createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
    return id;
  });
}
emulatorTest('direct connection requires two separate approvals and creates no token reward or escrow',async()=>{
  const {serverTimestamp}=require('firebase/firestore');await communitySeed();
  const id=await directConnect('student','teacher');
  const client=env.authenticatedContext('student').firestore();
  assert.equal((await db.doc(`profileConnections/${id}`).get()).data().status,'pending');
  await assertFails(updateDoc(doc(client,`profileConnections/${id}`),{confirmedBy:['student','teacher'],status:'confirmed',updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(client,`chats/${id}`),{id,participants:['student','teacher'],participantNames:{},kind:'in_person',credits:0,status:'active',createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
  await directConnect('teacher','student');await directConnect('student','teacher');
  assert.equal((await db.doc(`profileConnections/${id}`).get()).data().status,'confirmed');
  assert.equal((await db.collection('chats').get()).size,1);
  assert.equal((await db.collection('transactions').get()).size,0);
  assert.equal((await db.collection('escrows').get()).size,0);
  await assertFails(updateDoc(doc(client,'users/student'),{credits:999}));
});
emulatorTest('simultaneous direct connections create one chat and reject self or foreign confirmations',async()=>{
  await communitySeed();
  const ids=await Promise.all([directConnect('student','teacher'),directConnect('teacher','student')]);
  assert.equal(ids[0],ids[1]);assert.equal((await db.collection('chats').get()).size,1);
  await assertFails(directConnect('student','student'));
  const foreign=env.authenticatedContext('student2').firestore();
  await assertFails(getDoc(doc(foreign,`profileConnections/${ids[0]}`)));
  await db.doc('accountDeletions/student').set({status:'pending'});
  await assertFails(directConnect('teacher','missing-user'));
});
emulatorTest('profile photos allow only owner image creation and authenticated reads; reject unsafe files and replacements', async () => {
  const owner = env.authenticatedContext('photo-owner').storage('gs://demo-coetus.appspot.com');
  const other = env.authenticatedContext('other').storage('gs://demo-coetus.appspot.com');
  const anonymous = env.unauthenticatedContext().storage('gs://demo-coetus.appspot.com');
  const path = 'profilePhotos/photo-owner/avatar.png';
  await assertSucceeds(uploadBytes(ref(owner, path), Buffer.from('image'), {contentType: 'image/png'}));
  await assertSucceeds(getBytes(ref(other, path)));
  await assertFails(getBytes(ref(anonymous, path)));
  await assertFails(uploadBytes(ref(other, 'profilePhotos/photo-owner/other.png'), Buffer.from('image'), {contentType: 'image/png'}));
  await assertFails(uploadBytes(ref(owner, path), Buffer.from('replacement'), {contentType: 'image/png'}));
  await assertFails(uploadBytes(ref(owner, 'profilePhotos/photo-owner/script.svg'), Buffer.from('<svg/>'), {contentType: 'image/svg+xml'}));
  for (const folder of ['communityMedia/photo-owner/new', 'portfolioMedia/photo-owner/new', 'verificationEvidence/photo-owner/new']) {
    await assertFails(uploadBytes(ref(owner, `${folder}/clip.mp4`), Buffer.from('video'), {contentType: 'video/mp4'}));
  }
  await assertFails(uploadBytes(ref(owner, 'profilePhotos/photo-owner/large.jpg'), Buffer.alloc(5 * 1024 * 1024 + 1), {contentType: 'image/jpeg'}));
  await assertFails(uploadBytes(ref(owner, 'profilePhotos/photo-owner/empty.jpg'), Buffer.alloc(0), {contentType: 'image/jpeg'}));
  await assertFails(deleteObject(ref(other, path)));
  await db.doc('accountDeletions/photo-owner').set({status: 'pending'});
  await assertFails(getBytes(ref(owner, path)));
  await assertFails(uploadBytes(ref(owner, 'profilePhotos/photo-owner/deleted.jpg'), Buffer.from('image'), {contentType: 'image/jpeg'}));
  await assertFails(deleteObject(ref(owner, path)));
});
emulatorTest('removed endorsement endpoint cannot grant trust or tokens even for a completed match',async()=>{
  await seed();
  for (const uid of ['student','student2','teacher','stranger']) {
    await assert.rejects(api.endorseTeaching.run(request(uid,{sessionId:'student',skillId:'guitar',comment:'Bu kişi bana öğretti.'})),e=>e.code==='failed-precondition');
  }
  const owner=(await db.doc('users/teacher').get()).data();
  assert.equal(owner.credits,0);assert.equal(owner.trustScore,0);assert.equal(owner.verified,false);
  assert.equal((await db.collection('skillVerifications').get()).size,0);
  assert.equal((await db.collection('transactions').get()).size,0);
});
emulatorTest('removed endorsement endpoint still rejects unauthenticated requests',async()=>{
  await assert.rejects(api.endorseTeaching.run({data:{}}),e=>e.code==='unauthenticated');
});
emulatorTest('optional portfolios publish immediately without tokens, endorsements, or identity badges', async () => {
  await seed();
  await api.submitSkillEvidence.run(request('teacher', {entryId:'text',skillId:'guitar',description:'Çalışmamı yazıyla anlatıyorum.',paths:[]}));
  let user=(await db.doc('users/teacher').get()).data();
  assert.equal(user.trustScore,0);assert.equal(user.credits,0);assert.equal(user.verified,false);
  const path='portfolioMedia/teacher/example/one.png';
  await bucket.file(path).save(Buffer.from('sample'),{metadata:{contentType:'image/png'}});
  const data={entryId:'example',skillId:'guitar',description:'Gitar çalışma örneğim.',paths:[path]};
  await Promise.all([1,2].map(()=>api.submitSkillEvidence.run(request('teacher',data))));
  assert.equal((await db.doc('skillVerifications/example').get()).data().status,'published');
  user=(await db.doc('users/teacher').get()).data();
  assert.equal(user.trustScore,2);assert.equal(user.credits,0);assert.equal(user.verified,false);
  assert.equal((await db.doc('users/teacher/teachSkills/guitar').get()).data().verifiedName,undefined);
  await assertSucceeds(getDoc(doc(env.authenticatedContext('student').firestore(),'skillVerifications/example')));
  await api.reportPortfolioEntry.run(request('student',{entryId:'example',reason:'Bu çalışma başka bir kişiye ait.'}));
  assert.equal((await db.collection('contentReports').get()).size,1);
  await assert.rejects(api.deletePortfolioEntry.run(request('student',{entryId:'example'})));
  await api.deletePortfolioEntry.run(request('teacher',{entryId:'example'}));
  await api.deletePortfolioEntry.run(request('teacher',{entryId:'example'}));
  assert.equal((await db.doc('users/teacher').get()).data().trustScore,0);
});
emulatorTest('client cannot forge rewards, verification fields or approved records', async () => {
  await seed();
  const client = env.authenticatedContext('teacher').firestore();
  await assertFails(updateDoc(doc(client, 'users/teacher'), { credits: 500 }));
  await assertFails(updateDoc(doc(client, 'users/teacher'), { verified: true }));
  await assertFails(updateDoc(doc(client, 'users/teacher'), { verificationCount: 10 }));
  await assertFails(updateDoc(doc(client, 'users/teacher/teachSkills/guitar'), { verifiedName: 'Gitar', verifiedLevel: 5 }));
  await assertFails(setDoc(doc(client, 'skillVerifications/fake'), { ownerId: 'teacher', status: 'approved' }));
  await assertFails(setDoc(doc(client, 'users/teacher/verificationRewards/fake'), { amount: 50 }));
  await assertSucceeds(updateDoc(doc(client, 'users/teacher'), { bio: 'Gitar öğretiyorum.' }));
  const newUser = env.authenticatedContext('new-user').firestore();
  await assertFails(setDoc(doc(newUser, 'users/new-user'), { id: 'new-user', email: 'test@example.test', credits: 20 }));
});
emulatorTest('private pending evidence is restricted to owner and reviewer', async () => {
  await seed();
  await db.doc('skillVerifications/media_teacher_guitar').set({ ownerId: 'teacher', status: 'pending' });
  const path = 'verificationEvidence/teacher/media_teacher_guitar/two.png';
  const owner = env.authenticatedContext('teacher').storage('gs://demo-coetus.appspot.com');
  const stranger = env.authenticatedContext('stranger').storage('gs://demo-coetus.appspot.com');
  await assertSucceeds(uploadBytes(ref(owner, path), new Uint8Array([1, 2]), { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(owner, path), new Uint8Array([3]), { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(stranger, path + 'other'), new Uint8Array([1]), { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(owner, path + 'file'), new Uint8Array([1]), { contentType: 'application/pdf' }));
  await assertFails(getDoc(doc(env.authenticatedContext('stranger').firestore(), 'skillVerifications/media_teacher_guitar')));
  await assertFails(getBytes(ref(stranger, path)));
  const reviewer = env.authenticatedContext('reviewer', { verificationReviewer: true });
  await assertSucceeds(getDoc(doc(reviewer.firestore(), 'skillVerifications/media_teacher_guitar')));
  await assertSucceeds(getBytes(ref(reviewer.storage('gs://demo-coetus.appspot.com'), path)));
  await db.doc('skillVerifications/media_teacher_guitar').update({ status: 'approved' });
  await assertSucceeds(getBytes(ref(stranger, path)));
});
emulatorTest('clients cannot replace session participants or accept their own pending offer', async () => {
  await seed();
  const client = env.authenticatedContext('student').firestore();
  await assertFails(updateDoc(doc(client, 'sessions/student'), { teacherId: 'student' }));
  await db.doc('matches/pending').set({ requesterId: 'student', receiverId: 'teacher', status: 'pending', participants: ['student', 'teacher'], skillName: 'Gitar', credits: 30 });
  await assertFails(updateDoc(doc(client, 'matches/pending'), { status: 'accepted' }));
  await assertFails(setDoc(doc(client, 'sessions/fake'), { teacherId: 'student', studentId: 'student', matchId: 'pending', skill: 'Gitar', credits: 30, status: 'active' }));
});
emulatorTest('legitimate offer creation and receiver acceptance remain available', async () => {
  await seed();
  const student = env.authenticatedContext('student').firestore();
  const offer = { id: 'valid', requesterId: 'student', receiverId: 'teacher', status: 'pending',
    participants: ['student', 'teacher'], skillName: 'Gitar', credits: 30 };
  const session = { id: 'valid', matchId: 'valid', teacherId: 'teacher', studentId: 'student',
    skillName: 'Gitar', credits: 30, status: 'requested' };
  const send = writeBatch(student);
  send.set(doc(student, 'matches/valid'), offer);
  send.set(doc(student, 'sessions/valid'), session);
  await assertSucceeds(send.commit());
  const teacher = env.authenticatedContext('teacher').firestore();
  const accept = writeBatch(teacher);
  accept.update(doc(teacher, 'matches/valid'), { status: 'accepted' });
  accept.set(doc(teacher, 'sessions/valid'), { ...session, status: 'active' });
  await assertFails(accept.commit());
  await db.doc('users/student').update({credits: 100});
  await api.acceptLearningOffer.run(request('teacher', {matchId: 'valid'}));
  assert.equal((await db.doc('users/student').get()).data().credits, 70);
});

async function communitySeed() {
  await seed();
  await db.doc('users/student').update({credits: 100});
  await api.publishCommunityPost.run(request('teacher', {postId: 'post', skillId: 'guitar', caption: 'Yeni çalışmam'}));
}
emulatorTest('free likes and comments are idempotent and never deduct tokens', async () => {
  await communitySeed();
  await Promise.all([1,2].map(() => api.setCommunityLike.run(request('student', {postId:'post', liked:true}))));
  await Promise.all([1,2].map(() => api.addCommunityComment.run(request('student', {postId:'post', commentId:'comment', text:'Harika!'}))));
  let p = (await db.doc('communityPosts/post').get()).data();
  assert.equal(p.likeCount,1); assert.equal(p.commentCount,1);
  assert.equal((await db.doc('users/student').get()).data().credits,100);
  assert.equal((await db.collection('transactions').get()).size,0);
  await api.setCommunityLike.run(request('student',{postId:'post',liked:false}));
  assert.equal((await db.doc('communityPosts/post').get()).data().likeCount,0);
});
emulatorTest('concurrent support retries debit and credit exactly once', async () => {
  await communitySeed();
  const payload = {postId:'post', requestId:'same-request', amount:3};
  await Promise.all([1,2,3].map(() => api.supportCommunityPost.run(request('student',payload))));
  assert.equal((await db.doc('users/student').get()).data().credits,97);
  assert.equal((await db.doc('users/teacher').get()).data().credits,3);
  assert.equal((await db.doc('communityPosts/post').get()).data().supportTotal,3);
  assert.equal((await db.collection('transactions').get()).size,1);
  await assert.rejects(api.supportCommunityPost.run(request('teacher',{...payload,requestId:'self'})));
  await assert.rejects(api.supportCommunityPost.run(request('student',{...payload,amount:5})));
  await assert.rejects(api.supportCommunityPost.run(request('student',{...payload,requestId:'poor',amount:100})));
});
emulatorTest('public posts cannot reuse private proof and owner deletion hides content', async () => {
  await communitySeed();
  await assert.rejects(api.publishCommunityPost.run(request('teacher',{postId:'proof',skillId:'guitar',caption:'Kanıt',mediaPath:'verificationEvidence/teacher/media_teacher_guitar/one.png'})));
  await assert.rejects(api.deleteCommunityPost.run(request('student',{postId:'post'})));
  await api.deleteCommunityPost.run(request('teacher',{postId:'post'}));
  assert.equal((await db.doc('communityPosts/post').get()).data().status,'deleted');
  await assert.rejects(api.setCommunityLike.run(request('student',{postId:'post',liked:true})));
  await assertFails(getDoc(doc(env.authenticatedContext('student').firestore(),'communityPosts/post')));
});
emulatorTest('clients cannot forge public counters, tips, locks or payment state', async () => {
  await communitySeed(); const client=env.authenticatedContext('student').firestore();
  for (const [path,data] of [['communityPosts/post',{likeCount:999}],['users/student',{lockedCredits:999}],['sessions/student',{funded:true,status:'completed'}]]) {
    await assertFails(updateDoc(doc(client,path),data));
  }
  await assertFails(setDoc(doc(client,'communityPosts/fake'),{authorId:'student',status:'published'}));
  await assertFails(setDoc(doc(client,'transactions/fake'),{amount:100,toUserId:'student'}));
  await assertFails(updateDoc(doc(client,'users/student'),{portfolioTrust:6,peerApprovalCount:6}));
});
async function pending(id='funded',amount=30) {
  await db.doc('matches/'+id).set({requesterId:'student',receiverId:'teacher',participants:['student','teacher'],skillName:'Gitar',credits:amount,status:'pending'});
}
emulatorTest('acceptance locks once and only student completion transfers once', async () => {
  await communitySeed(); await pending();
  await Promise.all([1,2].map(() => api.acceptLearningOffer.run(request('teacher',{matchId:'funded'}))));
  let student=(await db.doc('users/student').get()).data();
  assert.equal(student.credits,70);assert.equal(student.lockedCredits,30);
  assert.equal((await db.doc('users/teacher').get()).data().credits,0);
  await assert.rejects(api.completeLearningSession.run(request('teacher',{sessionId:'funded'})));
  await Promise.all([1,2].map(() => api.completeLearningSession.run(request('student',{sessionId:'funded'}))));
  student=(await db.doc('users/student').get()).data();
  assert.equal(student.credits,70);assert.equal(student.lockedCredits,0);
  assert.equal((await db.doc('users/teacher').get()).data().credits,30);
  assert.equal((await db.collection('transactions').get()).size,2);
});
emulatorTest('refund needs both votes and cannot double refund', async () => {
  await communitySeed(); await pending();
  await api.acceptLearningOffer.run(request('teacher',{matchId:'funded'}));
  await api.cancelLearningSession.run(request('student',{sessionId:'funded'}));
  assert.equal((await db.doc('users/student').get()).data().credits,70);
  await Promise.all([1,2].map(() => api.cancelLearningSession.run(request('teacher',{sessionId:'funded'}))));
  const student=(await db.doc('users/student').get()).data();
  assert.equal(student.credits,100);assert.equal(student.lockedCredits,0);
  await assert.rejects(api.completeLearningSession.run(request('student',{sessionId:'funded'})));
});
emulatorTest('competing acceptances cannot overdraw student balance', async () => {
  await communitySeed(); await pending('first',80);await pending('second',80);
  const result=await Promise.allSettled(['first','second'].map(matchId=>api.acceptLearningOffer.run(request('teacher',{matchId}))));
  assert.equal(result.filter(r=>r.status==='fulfilled').length,1);
  const student=(await db.doc('users/student').get()).data();
  assert.equal(student.credits,20);assert.equal(student.lockedCredits,80);
});
emulatorTest('community media is private before publication and immutable afterwards',async()=>{
  await seed();
  const owner=env.authenticatedContext('teacher').storage('gs://demo-coetus.appspot.com');
  const other=env.authenticatedContext('student').storage('gs://demo-coetus.appspot.com');
  const path='communityMedia/teacher/withmedia/photo.png';
  await assertSucceeds(uploadBytes(ref(owner,path),new Uint8Array([1,2]),{contentType:'image/png'}));
  await assertFails(getBytes(ref(other,path)));
  await api.publishCommunityPost.run(request('teacher',{postId:'withmedia',skillId:'guitar',caption:'Çalışmam',mediaPath:path}));
  await assertSucceeds(getBytes(ref(other,path)));
  await assertFails(uploadBytes(ref(owner,path),new Uint8Array([3]),{contentType:'image/png'}));
  await assertFails(uploadBytes(ref(owner,path+'extra'),new Uint8Array([3]),{contentType:'image/png'}));
  await api.deleteCommunityPost.run(request('teacher',{postId:'withmedia'}));
  await assertFails(getBytes(ref(other,path)));
});

emulatorTest('portfolio trust counts distinct skills, is capped and rolls back when last sample is removed',async()=>{
  await seed();
  for (const skill of ['a','b','c','d']) {
    await db.doc(`users/teacher/teachSkills/${skill}`).set({name:skill,level:1});
    const path=`portfolioMedia/teacher/entry_${skill}/sample.png`;
    await bucket.file(path).save(Buffer.from('sample'),{metadata:{contentType:'image/png'}});
    await api.submitSkillEvidence.run(request('teacher',{entryId:'entry_'+skill,skillId:skill,description:'Çalışma örneği açıklaması',paths:[path]}));
  }
  assert.equal((await db.doc('users/teacher').get()).data().trustScore,6);
  await api.deletePortfolioEntry.run(request('teacher',{entryId:'entry_a'}));
  assert.equal((await db.doc('users/teacher').get()).data().trustScore,6);
  await api.deletePortfolioEntry.run(request('teacher',{entryId:'entry_b'}));
  assert.equal((await db.doc('users/teacher').get()).data().trustScore,4);
  assert.equal((await db.doc('users/teacher').get()).data().credits,0);
});

emulatorTest('public profile queries expose only published work and peer approvals',async()=>{
  await seed();
  await api.submitSkillEvidence.run(request('teacher',{entryId:'publictext',skillId:'guitar',description:'Metin çalışma örneği.',paths:[]}));
  await db.doc('skillVerifications/private').set({ownerId:'teacher',type:'media',status:'pending'});
  const client=env.authenticatedContext('student').firestore();
  const snapshot=await assertSucceeds(getDocs(query(collection(client,'skillVerifications'),where('ownerId','==','teacher'),where('status','in',['approved','published']))));
  assert.equal(snapshot.size,1);
  await assertFails(getDocs(query(collection(client,'skillVerifications'),where('ownerId','==','teacher'))));
  await assertFails(updateDoc(doc(env.authenticatedContext('teacher').firestore(),'users/teacher/teachSkills/guitar'),{peerApprovalCount:100}));
});

emulatorTest('profile completion atomically saves optional interests and normalized skill names',async()=>{
  await seed();
  const student=env.authenticatedContext('student').firestore();
  const batch=writeBatch(student);
  batch.update(doc(student,'users/student'),{displayName:'Deniz',bio:'',location:'',interests:['music','software'],onboardingVersion:2,profileCompleted:true,learnSkillNames:['python','gitar']});
  for(const [id,name,key] of [['python','Python','python'],['gitar','Gitar','gitar']]) batch.set(doc(student,'users/student/learnSkills/'+id),{id,name,normalizedName:key,level:1,learnable:true,teachable:false});
  await assertSucceeds(batch.commit());
  assert.equal((await db.doc('users/student').get()).data().profileCompleted,true);
  assert.equal((await db.collection('users/student/learnSkills').get()).size,2);
});

const deletionTest=(name,fn)=>test(name,{skip:!enabled||!process.env.FIREBASE_AUTH_EMULATOR_HOST},fn);
const deletionRequest=(uid,extra={})=>({auth:{uid,token:{auth_time:Math.floor(Date.now()/1000)}},data:{confirm:true,...extra}});
deletionTest('account deletion requires explicit confirmation and recent sign-in',async()=>{
  await seed();
  await assert.rejects(api.deleteAccount.run({data:{confirm:true}}),e=>e.code==='unauthenticated');
  await assert.rejects(api.deleteAccount.run({...deletionRequest('teacher'),auth:{uid:'teacher',token:{auth_time:1}}}),e=>e.code==='unauthenticated');
  await assert.rejects(api.deleteAccount.run(deletionRequest('teacher',{confirm:false})),e=>e.code==='invalid-argument');
  assert.equal((await db.doc('users/teacher').get()).exists,true);
  assert.equal((await db.collection('accountDeletions').get()).size,0);
});
deletionTest('locked sessions prevent deletion for either participant without changing balances',async()=>{
  await communitySeed();await pending();
  await api.acceptLearningOffer.run(request('teacher',{matchId:'funded'}));
  for(const uid of ['student','teacher'])await assert.rejects(api.deleteAccount.run(deletionRequest(uid)),e=>e.code==='failed-precondition');
  assert.equal((await db.collection('accountDeletions').get()).size,0);
  assert.equal((await db.doc('users/student').get()).data().credits,70);
  assert.equal((await db.doc('users/student').get()).data().lockedCredits,30);
});
deletionTest('deletion removes Auth, profile, authored content and media while retaining anonymous transaction history',async()=>{
  await communitySeed();
  const auth=require('firebase-admin/auth').getAuth();await auth.createUser({uid:'student',email:'student@example.test',password:'TestPassword123!'});
  await db.doc('users/student/learnSkills/python').set({name:'Python',level:1});
  await api.addCommunityComment.run(request('student',{postId:'post',commentId:'mine',text:'Kendi yorumumu yazıyorum.'}));
  await api.setCommunityLike.run(request('student',{postId:'post',liked:true}));
  await api.supportCommunityPost.run(request('student',{postId:'post',requestId:'tip',amount:3}));
  await db.doc('communityPosts/my-post').set({authorId:'student',status:'published'});
  await db.doc('communityPosts/my-post/comments/other').set({authorId:'teacher',text:'Başkasının yorumu'});
  await db.doc('skillVerifications/work').set({ownerId:'student',type:'portfolio',status:'published'});
  await db.doc('interestSuggestions/mine').set({ownerId:'student',name:'Astronomi',status:'pending'});
  await directClaim('student','delete_me');
  await db.doc('profileConnections/mine').set({participants:['student','teacher'],status:'pending'});
  await db.doc('chats/shared').set({participants:['student','teacher'],participantNames:{student:'Deniz',teacher:'Ece'},lastMessage:'Özel metnim',lastSenderId:'student'});
  await db.doc('chats/shared/messages/mine').set({senderId:'student',text:'Özel metnim'});
  await db.doc('chats/shared/messages/other').set({senderId:'teacher',text:'Karşı tarafın mesajı'});
  const path='portfolioMedia/student/work/file.png';await bucket.file(path).save(Buffer.from('private'),{metadata:{contentType:'image/png'}});
  await bucket.file('profilePhotos/student/avatar.png').save(Buffer.from('private'),{metadata:{contentType:'image/png'}});
  await bucket.file('profilePhotos/teacher/avatar.png').save(Buffer.from('other'),{metadata:{contentType:'image/png'}});
  const result=await api.deleteAccount.run(deletionRequest('student',{uid:'teacher'}));
  assert.equal(result.deleted,true);assert.equal(result.pendingCleanup,false);
  await assert.rejects(auth.getUser('student'),e=>e.code==='auth/user-not-found');
  assert.equal((await db.doc('users/student').get()).exists,false);
  assert.equal((await db.collection('users/student/learnSkills').get()).size,0);
  assert.equal((await db.doc('communityPosts/my-post').get()).exists,false);
  assert.equal((await db.doc('skillVerifications/work').get()).exists,false);
  assert.equal((await db.doc('interestSuggestions/mine').get()).exists,false);
  assert.equal((await db.doc('usernames/delete_me').get()).exists,false);
  assert.equal((await db.doc('profileConnections/mine').get()).exists,false);
  assert.equal((await db.doc('communityPosts/post').get()).data().likeCount,0);
  assert.equal((await db.doc('communityPosts/post').get()).data().commentCount,0);
  assert.equal((await db.doc('chats/shared/messages/mine').get()).exists,false);
  assert.equal((await db.doc('chats/shared/messages/other').get()).exists,true);
  assert.equal((await db.doc('chats/shared').get()).data().participantNames.student,'Silinmiş hesap');
  assert.equal((await db.collection('transactions').get()).size,1);
  assert.equal((await bucket.file(path).exists())[0],false);
  assert.equal((await bucket.file('profilePhotos/student/avatar.png').exists())[0],false);
  assert.equal((await bucket.file('profilePhotos/teacher/avatar.png').exists())[0],true);
  assert.equal((await db.doc('users/teacher').get()).exists,true);
  assert.equal((await db.doc('accountDeletions/student').get()).data().status,'completed');
  await api.cleanupDeletedAccount.run({uid:'student'});
  assert.equal((await db.doc('communityPosts/post').get()).data().commentCount,0);
});
deletionTest('deleting accounts cannot write, upload, call features, or recreate their profile with a stale token',async()=>{
  await communitySeed();
  await db.doc('accountDeletions/student').set({status:'processing'});
  await db.doc('users/student').update({accountDeletionPending:true});
  const actor=env.authenticatedContext('student'),client=actor.firestore();
  await assertFails(updateDoc(doc(client,'users/student'),{displayName:'Geri geldim'}));
  await assertFails(setDoc(doc(client,'users/student/teachSkills/fake'),{name:'Python',level:1}));
  await assertFails(uploadBytes(ref(actor.storage('gs://demo-coetus.appspot.com'),'communityMedia/student/new/sample.png'),new Uint8Array([1]),{contentType:'image/png'}));
  await assert.rejects(api.setCommunityLike.run(request('student',{postId:'post',liked:true})),e=>e.code==='failed-precondition');
  await db.doc('users/teacher').update({credits:5});
  await db.doc('communityPosts/deleting').set({authorId:'student',status:'published',supportTotal:0});
  await assert.rejects(api.supportCommunityPost.run(request('teacher',{postId:'deleting',requestId:'blocked',amount:1})),e=>e.code==='failed-precondition'&&e.message.includes('silinme'));
  assert.equal((await db.doc('users/teacher').get()).data().credits,5);
  await db.doc('users/student').delete();
  await assertFails(setDoc(doc(client,'users/student'),{id:'student',email:'student@example.test',credits:0}));
});

deletionTest('account deletion racing with session acceptance cannot lose locked funds',async()=>{
  await communitySeed();await pending('race',80);
  const auth=require('firebase-admin/auth').getAuth();await auth.createUser({uid:'teacher',email:'teacher@example.test',password:'TestPassword123!'});
  const results=await Promise.allSettled([api.acceptLearningOffer.run(request('teacher',{matchId:'race'})),api.deleteAccount.run(deletionRequest('teacher'))]);
  const accepted=results[0].status==='fulfilled',deleted=results[1].status==='fulfilled';
  assert.notEqual(accepted,deleted);
  const student=(await db.doc('users/student').get()).data();
  assert.equal(student.credits,accepted?20:100);
  assert.equal(student.lockedCredits||0,accepted?80:0);
  assert.equal((await db.doc('users/teacher').get()).exists,!deleted);
});

deletionTest('background Auth deletion preserves wallets if a console deletion bypasses the app guard',async()=>{
  await communitySeed();await pending('external',80);
  await api.acceptLearningOffer.run(request('teacher',{matchId:'external'}));
  await assert.rejects(api.cleanupDeletedAccount.run({uid:'teacher'}));
  assert.equal((await db.doc('users/teacher').get()).exists,true);
  assert.equal((await db.doc('users/student').get()).data().lockedCredits,80);
  assert.equal((await db.doc('escrows/external').get()).data().status,'locked');
});

emulatorTest('interest suggestions stay private and only interest moderators can publish', async () => {
  const owner = env.authenticatedContext('student').firestore();
  const other = env.authenticatedContext('student2').firestore();
  const moderator = env.authenticatedContext('moderator', { interestModerator: true }).firestore();
  const {serverTimestamp} = require('firebase/firestore');
  const suggestion = doc(owner, 'interestSuggestions/example');
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'interestSuggestions/anonymous'),
    {name:'Astronomi', ownerId:'student', status:'pending', createdAt:serverTimestamp()}));
  await assertFails(setDoc(suggestion, {name:'Astronomi', ownerId:'student', status:'approved', createdAt:serverTimestamp()}));
  await assertSucceeds(setDoc(suggestion, {name:'Astronomi', ownerId:'student', status:'pending', createdAt:serverTimestamp()}));
  await assertSucceeds(getDoc(suggestion));
  await assertFails(getDoc(doc(other, 'interestSuggestions/example')));
  await assertSucceeds(getDocs(query(collection(moderator,'interestSuggestions'),where('status','==','pending'))));
  await assertFails(updateDoc(suggestion, {status:'approved', reviewedBy:'student', reviewedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(moderator,'interestSuggestions/example'),
    {name:'Değiştirilmiş', status:'approved', reviewedBy:'moderator', reviewedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(moderator,'interestSuggestions/example'),
    {status:'approved', reviewedBy:'moderator', reviewedAt:serverTimestamp()}));
  await assertSucceeds(getDocs(query(collection(other,'interestSuggestions'),where('status','==','approved'))));
  await assertFails(setDoc(suggestion, {name:'Astronomi', ownerId:'student', status:'pending', createdAt:serverTimestamp()}));
});

emulatorTest('rejected interests cannot be published by their owner or edited after review', async () => {
  const {serverTimestamp} = require('firebase/firestore');
  const owner = env.authenticatedContext('student').firestore();
  const moderator = env.authenticatedContext('moderator', {interestModerator:true}).firestore();
  await assertSucceeds(setDoc(doc(owner,'interestSuggestions/rejected'),
    {name:'Öneri', ownerId:'student', status:'pending', createdAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(moderator,'interestSuggestions/rejected'),
    {status:'rejected', reviewedBy:'moderator', reviewedAt:serverTimestamp()}));
  await assertFails(getDoc(doc(env.authenticatedContext('student2').firestore(),'interestSuggestions/rejected')));
  await assertFails(updateDoc(doc(moderator,'interestSuggestions/rejected'),
    {status:'approved', reviewedBy:'moderator', reviewedAt:serverTimestamp()}));
});

emulatorTest('first match gift atomically awards twenty tokens only once', async () => {
  const {serverTimestamp, runTransaction} = require('firebase/firestore');
  await seed();
  await db.doc('users/student').update({credits:0});
  for (const uid of ['student','teacher']) {
    const client = env.authenticatedContext(uid).firestore();
    const reward = doc(client, `users/${uid}/rewards/first_match`);
    const user = doc(client, `users/${uid}`);
    const claim = () => runTransaction(client, async tx => {
      const existing = await tx.get(reward); if (existing.exists()) return false;
      const wallet = await tx.get(user);
      tx.set(reward, {amount:20, matchId:'student', createdAt:serverTimestamp()});
      tx.update(user, {credits:wallet.data().credits+20}); return true;
    }).catch(async error => {
      if (error.code === 'permission-denied' && (await getDoc(reward)).exists()) return false;
      throw error;
    });
    const results = await Promise.all([claim(),claim()]);
    assert.equal(results.filter(Boolean).length,1);
    assert.equal((await db.doc(`users/${uid}`).get()).data().credits,20);
    await assertFails(updateDoc(user,{credits:40}));
    await assertFails(updateDoc(reward,{amount:40}));
  }
});

emulatorTest('first match gift rejects forged, pending, foreign and unpaired wallet writes', async () => {
  const {serverTimestamp} = require('firebase/firestore');
  await seed();
  await db.doc('users/student').update({credits:0});
  await db.doc('matches/pending').set({status:'pending',participants:['student','teacher'],requesterId:'student',receiverId:'teacher'});
  const client = env.authenticatedContext('student').firestore();
  const reward = doc(client,'users/student/rewards/first_match');
  const wallet = doc(client,'users/student');
  await assertFails(setDoc(reward,{amount:20,matchId:'student',createdAt:serverTimestamp()}));
  for (const [matchId,amount] of [['missing',20],['pending',20],['student2',20],['student',200]]) {
    const batch = writeBatch(client);
    batch.set(reward,{amount,matchId,createdAt:serverTimestamp()}); batch.update(wallet,{credits:amount});
    await assertFails(batch.commit());
  }
  const batch = writeBatch(client);
  batch.set(reward,{amount:20,matchId:'student',createdAt:serverTimestamp()});
  batch.update(wallet,{credits:20,trustScore:100});
  await assertFails(batch.commit());
  assert.equal((await db.doc('users/student').get()).data().credits,0);
});

emulatorTest('welcome gift adds fifty once and preserves existing balance across concurrent logins', async () => {
  const {serverTimestamp,runTransaction} = require('firebase/firestore');
  await db.doc('users/new-user').set({id:'new-user',email:'new@example.test',credits:0});
  await db.doc('users/existing-user').set({id:'existing-user',email:'old@example.test',credits:37});
  for (const [uid,initial] of [['new-user',0],['existing-user',37]]) {
    const client=env.authenticatedContext(uid).firestore();
    const user=doc(client,`users/${uid}`),receipt=doc(client,`users/${uid}/rewards/welcome`);
    const login=()=>runTransaction(client,async tx=>{
      if((await tx.get(receipt)).exists())return false;
      const profile=await tx.get(user);
      tx.set(receipt,{amount:50,createdAt:serverTimestamp()});
      tx.update(user,{credits:profile.data().credits+50});return true;
    }).catch(async error=>{
      if(error.code==='permission-denied'&&(await getDoc(receipt)).exists())return false;
      throw error;
    });
    const results=await Promise.all([login(),login(),login()]);
    assert.equal(results.filter(Boolean).length,1);
    assert.equal(await login(),false);
    assert.equal((await db.doc(`users/${uid}`).get()).data().credits,initial+50);
    await assertFails(updateDoc(receipt,{amount:100}));
    const {deleteDoc}=require('firebase/firestore');await assertFails(deleteDoc(receipt));
    await assertFails(updateDoc(user,{credits:initial+100}));
  }
});

emulatorTest('welcome gift rejects arbitrary amounts, foreign wallets, account resets and orphan receipts',async()=>{
  const {serverTimestamp}=require('firebase/firestore');
  await db.doc('users/student').set({id:'student',email:'student@example.test',credits:0});
  await db.doc('users/teacher').set({id:'teacher',email:'teacher@example.test',credits:0});
  const client=env.authenticatedContext('student').firestore();
  const user=doc(client,'users/student'),receipt=doc(client,'users/student/rewards/welcome');
  await assertFails(setDoc(receipt,{amount:50,createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(client,'users/fake'),{id:'fake',email:'fake@example.test',credits:50}));
  for(const amount of [20,49,51,500]) {
    const batch=writeBatch(client);batch.set(receipt,{amount,createdAt:serverTimestamp()});batch.update(user,{credits:amount});await assertFails(batch.commit());
  }
  const foreign=writeBatch(client);foreign.set(doc(client,'users/teacher/rewards/welcome'),{amount:50,createdAt:serverTimestamp()});foreign.update(doc(client,'users/teacher'),{credits:50});await assertFails(foreign.commit());
  const extra=writeBatch(client);extra.set(receipt,{amount:50,createdAt:serverTimestamp()});extra.update(user,{credits:50,trustScore:100});await assertFails(extra.commit());
  await db.doc('accountDeletions/student').set({status:'completed'});
  const deleted=writeBatch(client);deleted.set(receipt,{amount:50,createdAt:serverTimestamp()});deleted.update(user,{credits:50});await assertFails(deleted.commit());
  assert.equal((await db.doc('users/student').get()).data().credits,0);
});

emulatorTest('welcome and first match gifts are separate and additive',async()=>{
  const {serverTimestamp}=require('firebase/firestore');await seed();await db.doc('users/student').update({credits:0});
  const client=env.authenticatedContext('student').firestore(),user=doc(client,'users/student');
  const welcome=writeBatch(client);welcome.set(doc(client,'users/student/rewards/welcome'),{amount:50,createdAt:serverTimestamp()});welcome.update(user,{credits:50});await assertSucceeds(welcome.commit());
  const match=writeBatch(client);match.set(doc(client,'users/student/rewards/first_match'),{amount:20,matchId:'student',createdAt:serverTimestamp()});match.update(user,{credits:70});await assertSucceeds(match.commit());
  assert.equal((await db.doc('users/student').get()).data().credits,70);
});

emulatorTest('welcome tokens fund the first learning session without requiring a prior match',async()=>{
  const {serverTimestamp}=require('firebase/firestore');
  for(const uid of ['student','teacher'])await db.doc(`users/${uid}`).set({id:uid,email:`${uid}@example.test`,credits:0});
  await db.doc('matches/first-funded').set({requesterId:'student',receiverId:'teacher',participants:['student','teacher'],status:'pending',skillName:'Gitar',credits:30});
  const client=env.authenticatedContext('student').firestore();
  const batch=writeBatch(client);batch.set(doc(client,'users/student/rewards/welcome'),{amount:50,createdAt:serverTimestamp()});batch.update(doc(client,'users/student'),{credits:50});await assertSucceeds(batch.commit());
  await api.acceptLearningOffer.run(request('teacher',{matchId:'first-funded'}));
  const student=(await db.doc('users/student').get()).data();
  assert.equal(student.credits,20);assert.equal(student.lockedCredits,30);
  assert.equal((await db.doc('sessions/first-funded').get()).data().funded,true);
});
