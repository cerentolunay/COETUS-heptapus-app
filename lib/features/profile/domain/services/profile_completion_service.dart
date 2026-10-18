import 'package:coetus/core/text/skill_normalization.dart';
import '../models/skill_model.dart';
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
      // Keep an incomplete state when the profile cannot be read.
      return false;
    }
  }

  /// Profil tamamlanmış olarak işaretle ve temel bilgileri kaydet
  Future<void> completeProfile({
    required String displayName,
    required String bio,
    required String location,
    String? photoUrl,
    List<String> interests = const [],
    List<SkillModel> skills = const [],
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (displayName.trim().length < 2 || displayName.trim().length > 50) {
      throw const FormatException('Geçerli bir görünen ad yaz.');
    }
    if (skills.any((s) => !s.learnable && !s.teachable)) {
      throw const FormatException('Her beceri için bir amaç seç.');
    }
    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final existingTeach = await userRef.collection('teachSkills').get();
    final existingLearn = await userRef.collection('learnSkills').get();
    final batch = _firestore.batch();
    final teachNames = {
      for (final d in existingTeach.docs)
        skillKey(d.data()['name'] as String? ?? ''),
    };
    final learnNames = {
      for (final d in existingLearn.docs)
        skillKey(d.data()['name'] as String? ?? ''),
    };
    for (final skill in skills) {
      final key = skillKey(skill.name);
      if (skill.teachable && !teachNames.contains(key)) {
        batch.set(
          userRef.collection('teachSkills').doc(skill.id),
          skill.copyWith(learnable: false).toMap(),
        );
        teachNames.add(key);
      }
      if (skill.learnable && !learnNames.contains(key)) {
        batch.set(
          userRef.collection('learnSkills').doc(skill.id),
          skill.copyWith(teachable: false).toMap(),
        );
        learnNames.add(key);
      }
    }
    batch.set(userRef, {
      if (!snapshot.exists) 'id': user.uid,
      if (!snapshot.exists) 'email': user.email ?? '',
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'displayName': displayName.trim(),
      'name': displayName.trim(),
      'bio': bio.trim(),
      'location': location.trim(),
      if (photoUrl?.trim().isNotEmpty == true) 'photoUrl': photoUrl!.trim(),
      'interests': interests.toSet().toList(),
      'teachSkillNames': teachNames.where((n) => n.isNotEmpty).toList(),
      'learnSkillNames': learnNames.where((n) => n.isNotEmpty).toList(),
      'profileCompleted': true,
      'onboardingVersion': 2,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Completion and chosen skills commit together; a failed save cannot mark an incomplete setup as finished.
    await batch.commit();
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
          // Listener reports the failure without marking a profile complete.
          return false;
        });
  }
}
