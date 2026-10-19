import 'package:cloud_firestore/cloud_firestore.dart';

/// A fixed reward guarded atomically by Firestore rules; no callable required.
class FirstMatchGift {
  static const amount = 20;
  static Future<bool> claim(String uid) async {
    final db = FirebaseFirestore.instance;
    final profile = await db.doc('users/$uid').get();
    if (profile.data()?['signupRewardVersion'] == 2) return false;
    final reward = db.doc('users/$uid/rewards/first_match');
    if ((await reward.get()).exists) return false;
    final matches = await db
        .collection('matches')
        .where('participants', arrayContains: uid)
        .get();
    final accepted = matches.docs.where(
      (doc) => doc.data()['status'] == 'accepted',
    );
    if (accepted.isEmpty) return false;
    final matchId = accepted.first.id;
    try {
      return await db.runTransaction((tx) async {
        final existing = await tx.get(reward);
        if (existing.exists) return false;
        final user = await tx.get(db.doc('users/$uid'));
        if (user.data()?['signupRewardVersion'] == 2) return false;
        final balance = user.data()?['credits'];
        if (balance is! int) throw StateError('Token bakiyesi okunamadı.');
        tx.set(reward, {
          'amount': amount,
          'matchId': matchId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(user.reference, {'credits': balance + amount});
        return true;
      });
    } on FirebaseException catch (error) {
      // A simultaneous claim may commit first and turn this create into a
      // denied update. Confirm the immutable receipt before treating it as done.
      if (error.code == 'permission-denied' && (await reward.get()).exists) {
        return false;
      }
      rethrow;
    }
  }
}
