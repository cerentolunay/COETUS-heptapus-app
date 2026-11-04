import 'package:cloud_firestore/cloud_firestore.dart';

/// One welcome grant per authenticated UID, enforced by an immutable receipt.
class WelcomeGiftService {
  WelcomeGiftService(this.firestore);
  static const amount = 200;
  static const rewardVersion = 2;
  static const legacyAmount = 50;
  final FirebaseFirestore firestore;

  Future<void> claim(String uid) async {
    final user = firestore.doc('users/$uid');
    final receipt = user.collection('rewards').doc('welcome');
    try {
      await firestore.runTransaction((tx) async {
        if ((await tx.get(receipt)).exists) return;
        final profile = await tx.get(user);
        if (!profile.exists) {
          throw StateError('Önce profil oluşturulmalı.');
        }
        final balance = profile.data()?['credits'] ?? 0;
        final grant = profile.data()?['signupRewardVersion'] == rewardVersion
            ? amount
            : legacyAmount;
        if (balance is! int || balance < 0) {
          throw StateError('Token bakiyesi geçersiz.');
        }
        tx.set(receipt, {
          'amount': grant,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(user, {'credits': balance + grant});
      });
    } on FirebaseException catch (error) {
      // A concurrent login may have committed the same gift first.
      if (error.code == 'permission-denied' && (await receipt.get()).exists) {
        return;
      }
      rethrow;
    }
  }
}
