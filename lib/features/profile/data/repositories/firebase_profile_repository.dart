import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:coetus/features/auth/domain/models/app_user.dart';

import '../../domain/models/profile_data.dart';
import '../../domain/models/skill_model.dart';
import '../../domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Future<ProfileData> loadProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return const ProfileData(
        user: AppUser(id: '', name: '', email: '', bio: ''),
        teachSkills: [],
        learnSkills: [],
      );
    }

    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await userDoc.get();
    final data = snapshot.data() ?? <String, dynamic>{};

    final teachSkills = await _readSkills(userDoc.collection('teachSkills'));
    final learnSkills = await _readSkills(userDoc.collection('learnSkills'));

    final user = AppUser.fromMap({
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? data['email'] ?? '',
      'name': firebaseUser.displayName ?? data['name'] ?? '',
      'bio': data['bio'] ?? '',
      'trustScore': data['trustScore'] ?? 0,
      'credits': data['credits'] ?? 0,
      'verified': data['verified'] ?? false,
    });

    return ProfileData(
      user: user,
      teachSkills: teachSkills,
      learnSkills: learnSkills,
    );
  }

  @override
  Future<ProfileData> updateProfile(AppUser user) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return loadProfile();
    }

    await _firestore.collection('users').doc(firebaseUser.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
    await firebaseUser.updateDisplayName(user.name);

    return loadProfile();
  }

  @override
  Future<ProfileData> saveTeachSkill(SkillModel skill) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    await _firestore.collection('users').doc(userId).collection('teachSkills').doc(skill.id).set(
          skill.toMap(),
          SetOptions(merge: true),
        );

    return loadProfile();
  }

  @override
  Future<ProfileData> deleteTeachSkill(String skillId) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    await _firestore.collection('users').doc(userId).collection('teachSkills').doc(skillId).delete();
    return loadProfile();
  }

  @override
  Future<ProfileData> saveLearnSkill(SkillModel skill) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    await _firestore.collection('users').doc(userId).collection('learnSkills').doc(skill.id).set(
          skill.toMap(),
          SetOptions(merge: true),
        );

    return loadProfile();
  }

  @override
  Future<ProfileData> deleteLearnSkill(String skillId) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    await _firestore.collection('users').doc(userId).collection('learnSkills').doc(skillId).delete();
    return loadProfile();
  }

  Future<List<SkillModel>> _readSkills(CollectionReference<Map<String, dynamic>> collection) async {
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) {
      return SkillModel.fromMap({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }
}
