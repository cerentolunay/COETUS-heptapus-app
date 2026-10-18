'use strict';
const {getFirestore} = require('firebase-admin/firestore');
const {HttpsError} = require('firebase-functions/v2/https');
async function requireActiveAccount(request) {
  if (!request.auth) throw new HttpsError('unauthenticated','Önce giriş yapmalısın.');
  if ((await getFirestore().doc(`accountDeletions/${request.auth.uid}`).get()).exists)
    throw new HttpsError('failed-precondition','Hesabın silinme sürecinde.');
  return request.auth.uid;
}
function requireUsableProfile(data) {
  if (data?.accountDeletionPending) throw new HttpsError('failed-precondition','Bu hesap silinme sürecinde.');
}
module.exports={requireActiveAccount,requireUsableProfile};
