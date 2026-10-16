const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, writeBatch, collection, query, where, getDocs } = require('firebase/firestore');
const { ref, uploadBytes, getBytes } = require('firebase/storage');
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
beforeEach(async () => { if (enabled) { await env.clearFirestore(); await env.clearStorage(); } });
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
emulatorTest('parallel student endorsements grant exactly one reward per skill', async () => {
  await seed();
  await Promise.all(['student', 'student2'].map(student => api.endorseTeaching.run(request(student,
    { sessionId: student, skillId: 'guitar', comment: 'Bu kişiden gitar öğrendim.' }))));
  const user = (await db.doc('users/teacher').get()).data();
  assert.equal(user.credits, 10); assert.equal(user.trustScore, 10); assert.equal(user.verificationCount, 1);
  assert.equal((await db.collection('transactions').get()).size, 1);
  assert.equal((await db.collection('skillVerifications').get()).size, 2);
  await assert.rejects(api.endorseTeaching.run(request('student',
    { sessionId: 'student', skillId: 'guitar', comment: 'Yeniden ödül istiyorum.' })), e => e.code === 'already-exists');
});
emulatorTest('self and stranger endorsements cannot award credits', async () => {
  await seed();
  for (const uid of ['teacher', 'stranger']) {
    await assert.rejects(api.endorseTeaching.run(request(uid,
      { sessionId: 'student', skillId: 'guitar', comment: 'Onay vermeye çalışıyorum.' })), e => e.code === 'permission-denied');
  }
  assert.equal((await db.doc('users/teacher').get()).data().credits, 0);
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
emulatorTest('active or unfunded sessions cannot produce peer endorsements',async()=>{
  await seed();
  for (const change of [{status:'active',funded:true},{status:'completed',funded:false}]) {
    await db.doc('sessions/student').update(change);
    await assert.rejects(api.endorseTeaching.run(request('student',{sessionId:'student',skillId:'guitar',comment:'Gerçek bir onay vermek istiyorum.'})), e=>e.code==='permission-denied');
  }
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
