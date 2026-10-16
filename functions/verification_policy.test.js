const test = require('node:test');
const assert = require('node:assert/strict');
const { approvalEffect, canEndorse, validMedia, portfolioContribution } = require('./verification_policy');
test('peer approval trust is distinct from per-skill token rewards and caps at 30', () => {
  let user={credits:0,trustScore:0,verificationCount:0,peerApprovalCount:0};
  user=approvalEffect(user,false);
  assert.equal(user.credits,10);assert.equal(user.trustScore,5);
  user=approvalEffect(user,true);
  assert.equal(user.credits,10);assert.equal(user.trustScore,10);
  for(let i=0;i<10;i++) user=approvalEffect(user,true);
  assert.equal(user.trustScore,30);assert.equal(user.credits,10);
  assert.equal(approvalEffect({credits:30,trustScore:30,verificationCount:3,peerApprovalCount:6},false).reward,0);
});
test('optional portfolio contribution is capped at six and ignores empty skills',()=>{
  assert.equal(portfolioContribution({a:0}),0);
  assert.equal(portfolioContribution({a:5}),2);
  assert.equal(portfolioContribution({a:5,b:1,c:1,d:2}),6);
});
test('only the actual student on an accepted matching skill can endorse', () => {
  const s = { teacherId: 'teacher', studentId: 'student', skill: 'Gitar', status: 'completed', funded:true };
  const m = { requesterId: 'student', receiverId: 'teacher', status: 'accepted' };
  assert.equal(canEndorse(s, m, 'student', { name: 'Gitar' }), true);
  assert.equal(canEndorse(s, m, 'teacher', { name: 'Gitar' }), false);
  assert.equal(canEndorse(s, m, 'stranger', { name: 'Gitar' }), false);
  assert.equal(canEndorse(s, m, 'student', { name: 'Kodlama' }), false);
  assert.equal(canEndorse({ ...s, status: 'requested' }, m, 'student', { name: 'Gitar' }), false);
  assert.equal(canEndorse(s, { ...m, status: 'pending' }, 'student', { name: 'Gitar' }), false);
});
test('media limits reject oversized, unsupported, and empty uploads', () => {
  assert.equal(validMedia('image/jpeg', 10 * 1024 * 1024), true);
  assert.equal(validMedia('video/mp4', 50 * 1024 * 1024), true);
  assert.equal(validMedia('image/jpeg', 11 * 1024 * 1024), false);
  assert.equal(validMedia('video/mp4', 51 * 1024 * 1024), false);
  assert.equal(validMedia('application/pdf', 10), false);
  assert.equal(validMedia('image/png', 0), false);
});
