'use strict';
// Run only with trusted administrator credentials; never ship credentials in the app.
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const uid = process.argv[2];
if (!uid) { console.error('Usage: node grant_reviewer.js <firebase-user-uid>'); process.exit(1); }
initializeApp({ credential: applicationDefault(), projectId: 'coetus-bc9c6' });
(async () => {
  const user = await getAuth().getUser(uid);
  await getAuth().setCustomUserClaims(uid, { ...user.customClaims, verificationReviewer: true });
  console.log('Reviewer role granted. The user must sign out and sign in again.');
})().catch(error => { console.error(error.message); process.exitCode = 1; });
