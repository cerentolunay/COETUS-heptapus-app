const {test,before,beforeEach,after}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('@firebase/rules-unit-testing');
const {doc,setDoc,updateDoc,getDoc,writeBatch,runTransaction,serverTimestamp,Timestamp}=require('firebase/firestore');
const enabled=!!process.env.FIRESTORE_EMULATOR_HOST;
let env,db,api;
before(async()=>{
  if(!enabled)return;
  env=await initializeTestEnvironment({projectId:'demo-coetus',firestore:{rules:fs.readFileSync(require('path').join(__dirname,'../firestore.rules'),'utf8')}});
  process.env.GCLOUD_PROJECT='demo-coetus';process.env.FIREBASE_CONFIG=JSON.stringify({projectId:'demo-coetus',storageBucket:'demo-coetus.appspot.com'});
  api=require('./index');
  db=require('firebase-admin/firestore').getFirestore();
});
beforeEach(async()=>{if(enabled)await env.clearFirestore();});
after(async()=>{if(enabled){await env.cleanup();await require('firebase-admin/app').deleteApp(require('firebase-admin/app').getApp());}});
const check=(name,fn)=>test(name,{skip:!enabled},fn);
const client=uid=>env.authenticatedContext(uid).firestore();
const timeout=require('./mutual_timeout');
async function seed(){
  for(const uid of ['a','b','outsider'])await db.doc('users/'+uid).set({id:uid,email:uid+'@example.test',credits:200,lockedCredits:0,signupRewardVersion:2});
  for(const [uid,kind,id,name,level] of [['a','teachSkills','python','Python',4],['a','learnSkills','guitar','Gitar',1],['b','teachSkills','guitar','Gitar',6],['b','learnSkills','python','Python',1]])
    await db.doc(`users/${uid}/${kind}/${id}`).set({id,name,normalizedName:name.toLowerCase(),level});
}
function proposal(){return {id:'mutual',matchId:'mutual',schemaVersion:2,requesterId:'a',receiverId:'b',participants:['a','b'],participantNames:{a:'A',b:'B'},
  teachSkillIds:{a:'python',b:'guitar'},learnSkillIds:{a:'guitar',b:'python'},taughtNames:{a:'Python',b:'Gitar'},levels:{a:4,b:6},
  skill:'Python ↔ Gitar',credits:60,deposits:{a:60,b:40},status:'requested',funded:false,completionVotes:[],cancellationVotes:[],
  completionRequestedAt:null,remindedAt:null,disputedBy:null,disputeReason:'',settledAt:null,createdAt:serverTimestamp(),updatedAt:serverTimestamp()};}
async function propose(patch={}){
  const c=client('a'),batch=writeBatch(c),s={...proposal(),...patch};
  batch.set(doc(c,'sessions/mutual'),s);
  batch.set(doc(c,'matches/mutual'),{id:'mutual',schemaVersion:2,initiatorId:'a',recipientId:'b',participants:['a','b'],skillName:s.skill,credits:s.credits,deposits:s.deposits,status:'pending',createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
  batch.set(doc(c,'chats/mutual'),{id:'mutual',participants:['a','b'],status:'pending'});
  await batch.commit();
}
async function accept(uid='b',omit=null){
  const c=client(uid);
  await runTransaction(c,async tx=>{
    const ref=doc(c,'sessions/mutual'),snap=await tx.get(ref),s=snap.data();
    if(s.status==='active')return;
    const users=await Promise.all(s.participants.map(id=>tx.get(doc(c,'users/'+id))));
    users.forEach(u=>{if(u.id!==omit)tx.update(u.ref,{credits:u.data().credits-s.deposits[u.id],lockedCredits:u.data().lockedCredits+s.deposits[u.id],lastExchangeSessionId:'mutual'});});
    tx.update(ref,{status:'active',funded:true,updatedAt:serverTimestamp()});
    tx.update(doc(c,'matches/mutual'),{status:'accepted',updatedAt:serverTimestamp()});
    tx.update(doc(c,'chats/mutual'),{status:'active',updatedAt:serverTimestamp()});
  });
}
async function action(uid,kind,extra={}){
  const c=client(uid);
  await runTransaction(c,async tx=>{
    const ref=doc(c,'sessions/mutual'),snap=await tx.get(ref),s=snap.data();
    if(['completed','cancelled','expired'].includes(s.status))return;
    const patch={updatedAt:serverTimestamp()};let terminal=false;
    if(kind==='complete'){
      if(s.completionVotes.includes(uid))return;
      patch.completionVotes=[...s.completionVotes,uid];
      if(!s.completionVotes.length)patch.completionRequestedAt=serverTimestamp();
      else{patch.status='completed';patch.settledAt=serverTimestamp();terminal=true;}
    }else if(kind==='cancel'){
      if(s.cancellationVotes.includes(uid))return;
      patch.cancellationVotes=[...s.cancellationVotes,uid];
      if(patch.cancellationVotes.length===2){patch.status='cancelled';patch.settledAt=serverTimestamp();terminal=true;}
      else if(s.completionVotes.length&&s.status==='active')Object.assign(patch,{status:'disputed',disputedBy:uid,disputeReason:'Tamamlanma isteğinden sonra iptal istendi.'});
    }else if(kind==='dispute')Object.assign(patch,{status:'disputed',disputedBy:uid,disputeReason:'Karşılıklı çalışma henüz tamamlanmadı.'});
    else if(kind==='remind')patch.remindedAt=serverTimestamp();
    else if(kind==='expire'){patch.status='expired';patch.settledAt=serverTimestamp();terminal=true;}
    const users=terminal?await Promise.all(s.participants.map(id=>tx.get(doc(c,'users/'+id)))):[];
    Object.assign(patch,extra);
    users.forEach(u=>tx.update(u.ref,{credits:u.data().credits+s.deposits[u.id],lockedCredits:u.data().lockedCredits-s.deposits[u.id],lastExchangeSessionId:'mutual'}));
    tx.update(ref,patch);
    if(terminal)tx.update(doc(c,'chats/mutual'),{status:patch.status,updatedAt:serverTimestamp()});
  });
}
async function backdate(hours){await db.doc('sessions/mutual').update({completionRequestedAt:require('firebase-admin/firestore').Timestamp.fromMillis(Date.now()-hours*3600000)});}
async function balances(a,b,lockedA,lockedB){const x=(await db.doc('users/a').get()).data(),y=(await db.doc('users/b').get()).data();assert.deepEqual([x.credits,y.credits,x.lockedCredits,y.lockedCredits],[a,b,lockedA,lockedB]);}
check('mutual proposals require both skill directions and freeze asymmetric level-based deposits',async()=>{
  await seed();await assertFails(propose({deposits:{a:60,b:60}}));
  await assertFails(propose({learnSkillIds:{a:'missing',b:'python'}}));
  await assertSucceeds(propose());await balances(200,200,0,0);
  await assertFails(updateDoc(doc(client('a'),'sessions/mutual'),{deposits:{a:10,b:10},updatedAt:serverTimestamp()}));
});
check('acceptance locks both or neither; wrong actor, missing wallet and insufficient balance are rejected',async()=>{
  await seed();await propose();await assertFails(accept('a'));await assertFails(accept('b','a'));await balances(200,200,0,0);
  await db.doc('users/a').update({credits:20});await assertFails(accept());await balances(20,200,0,0);
  await db.doc('users/a').update({credits:200});await assertSucceeds(accept());await accept();await balances(140,160,60,40);
});
check('two distinct completion votes refund each own deposit once without transferring or minting',async()=>{
  await seed();await propose();await accept();await action('a','complete');await balances(140,160,60,40);
  await assertFails(updateDoc(doc(client('a'),'sessions/mutual'),{completionVotes:['a','b'],status:'completed',settledAt:serverTimestamp(),updatedAt:serverTimestamp()}));
  await assertSucceeds(action('b','complete'));await action('b','complete');await balances(200,200,0,0);
  await assertFails(updateDoc(doc(client('a'),'users/a'),{credits:260,lastExchangeSessionId:'mutual'}));
});
check('24-hour reminder is one-time, server-timed, and cannot extend the deadline',async()=>{
  await seed();await propose();await accept();await action('a','complete');
  await assertFails(action('a','remind'));await backdate(25);await assertSucceeds(action('a','remind'));
  await assertFails(action('a','remind'));await assertFails(updateDoc(doc(client('a'),'sessions/mutual'),{completionRequestedAt:serverTimestamp(),updatedAt:serverTimestamp()}));
  await balances(140,160,60,40);
});
check('72-hour silence expires without marking completion and atomically refunds both deposits',async()=>{
  await seed();await propose();await accept();await action('a','complete');
  await assertFails(action('a','expire'));await backdate(73);await assertSucceeds(action('b','expire'));await balances(200,200,0,0);
  const s=(await db.doc('sessions/mutual').get()).data();assert.equal(s.status,'expired');assert.deepEqual(s.completionVotes,['a']);
  await action('a','expire');await balances(200,200,0,0);
});
check('timely objection blocks expiry; mutual cancellation can resolve a disputed exchange',async()=>{
  await seed();await propose();await accept();await action('a','complete');
  await assertFails(action('a','dispute'));await assertSucceeds(action('b','dispute'));await backdate(73);
  await assertFails(action('a','expire'));await assertSucceeds(action('a','complete'));await assertFails(action('b','complete'));
  await action('a','cancel');await balances(140,160,60,40);await action('b','cancel');await balances(200,200,0,0);
});
check('late objection is rejected; cancelling a pending completion blocks automatic closure',async()=>{
  await seed();await propose();await accept();await action('a','complete');await backdate(73);
  await assertFails(action('b','dispute'));await assertFails(action('b','cancel'));
  await backdate(1);await assertSucceeds(action('b','cancel'));await backdate(73);
  await assertFails(action('a','expire'));await action('a','cancel');await balances(200,200,0,0);
});
check('foreign actors, orphan refunds and one-sided settlements cannot access or alter funds',async()=>{
  await seed();await propose();await accept();await action('a','complete');await backdate(73);
  await assertFails(getDoc(doc(client('outsider'),'sessions/mutual')));
  await assertFails(action('outsider','expire'));
  const c=client('a'),batch=writeBatch(c);
  batch.update(doc(c,'sessions/mutual'),{status:'expired',settledAt:serverTimestamp(),updatedAt:serverTimestamp()});
  batch.update(doc(c,'users/a'),{credits:200,lockedCredits:0,lastExchangeSessionId:'mutual'});
  await assertFails(batch.commit());await balances(140,160,60,40);
});
check('simultaneous completion and cancellation preserve a single terminal result and total balance',async()=>{
  await seed();await propose();await accept();await action('a','complete');await action('a','cancel');
  await Promise.allSettled([action('b','cancel'),action('b','complete')]);
  assert.equal((await db.doc('sessions/mutual').get()).data().status,'cancelled');await balances(200,200,0,0);
});

check('legacy one-way callables cannot accept or settle a mutual exchange',async()=>{
  await seed();await propose();
  await assert.rejects(api.acceptLearningOffer.run({auth:{uid:'b',token:{}},data:{matchId:'mutual'}}));
  await balances(200,200,0,0);await accept();
  await assert.rejects(api.completeLearningSession.run({auth:{uid:'a',token:{}},data:{sessionId:'mutual'}}));
  await assert.rejects(api.cancelLearningSession.run({auth:{uid:'b',token:{}},data:{sessionId:'mutual'}}));
  await balances(140,160,60,40);
});

check('server queues first confirmation, reminds once and expires without an open app',async()=>{
  await seed();await propose();await accept();await action('a','complete');
  const start=(await db.doc('sessions/mutual').get()).data().completionRequestedAt.toMillis();
  await timeout.syncTimeout(db,'mutual');
  assert.equal((await db.doc('exchangeTimeoutJobs/mutual').get()).data().dueAt.toMillis(),start+24*3600000);
  assert.equal(await timeout.sweepTimeouts(db,start+24*3600000-1),0);
  assert.equal(await timeout.sweepTimeouts(db,start+24*3600000),1);
  assert.equal(await timeout.processTimeout(db,'mutual',start+25*3600000),'waiting');
  await balances(140,160,60,40);
  assert.equal(await timeout.sweepTimeouts(db,start+72*3600000),1);
  await balances(200,200,0,0);
  assert.equal((await db.doc('sessions/mutual').get()).data().status,'expired');
  assert.equal((await db.collection('notifications').get()).size,3);
  assert.equal((await db.doc('exchangeTimeoutJobs/mutual').get()).exists,false);
});
check('server duplicate concurrent expiry refunds both deposits only once',async()=>{
  await seed();await propose();await accept();await action('a','complete');await backdate(73);
  await Promise.all([timeout.processTimeout(db,'mutual'),timeout.processTimeout(db,'mutual')]);
  await balances(200,200,0,0);
  await timeout.syncTimeout(db,'mutual');
  assert.equal((await db.doc('exchangeTimeoutJobs/mutual').get()).exists,false);
});
check('server rechecks objection and cancellation even with a stale due job',async()=>{
  for(const kind of ['dispute','cancel']){
    await env.clearFirestore();await seed();await propose();await accept();await action('a','complete');
    await timeout.syncTimeout(db,'mutual');await action('b',kind);await backdate(73);
    assert.equal(await timeout.processTimeout(db,'mutual'),'ignored');
    await balances(140,160,60,40);
    assert.equal((await db.doc('sessions/mutual').get()).data().status,'disputed');
  }
});
check('server refuses a damaged wallet atomically and retains its job for investigation',async()=>{
  await seed();await propose();await accept();await action('a','complete');await backdate(73);
  await timeout.syncTimeout(db,'mutual');await db.doc('users/b').update({lockedCredits:0});
  await assert.rejects(timeout.processTimeout(db,'mutual'),/Invalid mutual wallet/);
  assert.equal((await db.doc('users/a').get()).data().credits,140);
  assert.equal((await db.doc('sessions/mutual').get()).data().status,'active');
  assert.equal((await db.doc('exchangeTimeoutJobs/mutual').get()).exists,true);
});
check('server ignores legacy and unfunded sessions; clients cannot forge timeout jobs',async()=>{
  await seed();await propose();await timeout.syncTimeout(db,'mutual');
  assert.equal((await db.doc('exchangeTimeoutJobs/mutual').get()).exists,false);
  await db.doc('sessions/legacy').set({schemaVersion:1,status:'active'});
  assert.equal(await timeout.processTimeout(db,'legacy'),'ignored');
  await assertFails(setDoc(doc(client('a'),'exchangeTimeoutJobs/mutual'),{dueAt:Timestamp.now()}));
});
