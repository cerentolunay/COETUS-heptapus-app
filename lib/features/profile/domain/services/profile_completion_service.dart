import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Profile completion service - checks and updates profile completion status
class ProfileCompletionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  ProfileCompletionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Mevcut kullanıcının profile'ı tamamlayıp tamamlamadığını kontrol et
  Future<bool> isProfileCompleted() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      return doc.data()?['profileCompleted'] as bool? ?? false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  /// Profil tamamlanmış olarak işaretle ve temel bilgileri kaydet
  Future<void> completeProfile({
    required String displayName,
    required String bio,
    required String location,
    String? photoUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final now = DateTime.now();

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();

      final data = {
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName.trim(),
        'bio': bio.trim(),
        'location': location.trim(),
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        'profileCompleted': true,
        'updatedAt': Timestamp.fromDate(now),
      };

      // Eğer yeni document ise createdAt ekle
      if (!docSnapshot.exists) {
        data['createdAt'] = Timestamp.fromDate(now);
      }

      await userRef.set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error completing profile: $e');
      rethrow;
    }
  }

  /// Real-time profile completion status stream
  Stream<bool> profileCompletionStream() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          return snapshot.data()?['profileCompleted'] as bool? ?? false;
        })
        .handleError((e) {
          print('Error in profileCompletionStream: $e');
          return false;
        });
  }
}
