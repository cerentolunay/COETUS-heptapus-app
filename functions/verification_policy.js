'use strict';
const REWARD = 10, MAX_REWARDED_SKILLS = 3;
function approvalEffect(user, alreadyRewarded) {
  const count = Number(user.verificationCount || 0), peerCount = Number(user.peerApprovalCount || 0);
  const reward = !alreadyRewarded && count < MAX_REWARDED_SKILLS ? REWARD : 0;
  return {reward, verificationCount: alreadyRewarded ? count : count+1, peerApprovalCount:peerCount+1,
    credits:Number(user.credits || 0)+reward,
    trustScore:Math.min(100,Number(user.trustScore || 0)+Math.min(30,(peerCount+1)*5)-Math.min(30,peerCount*5))};
}
function portfolioContribution(counts) { return Math.min(3,Object.values(counts).filter(n=>n>0).length)*2; }
function canEndorse(session, match, uid, skill) {
  return uid === session.studentId && uid !== session.teacherId && session.status === 'completed' && session.funded === true &&
    match.status === 'accepted' && match.requesterId === uid && match.receiverId === session.teacherId &&
    (session.skill || session.skillName) === skill.name;
}
function validMedia(contentType, bytes) {
  return Number(bytes)>0 && ((['image/jpeg','image/png','image/webp'].includes(contentType) && bytes<=10*1024*1024) ||
    (['video/mp4','video/quicktime','video/webm'].includes(contentType) && bytes<=50*1024*1024));
}
module.exports={REWARD,MAX_REWARDED_SKILLS,approvalEffect,canEndorse,validMedia,portfolioContribution};
