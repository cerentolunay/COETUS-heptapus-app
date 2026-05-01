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
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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
      'displayName':
          data['displayName'] ?? data['name'] ?? firebaseUser.displayName ?? '',
      'name': firebaseUser.displayName ?? data['name'] ?? '',
      'bio': data['bio'] ?? '',
      'location': data['location'] ?? '',
      'photoUrl': data['photoUrl'] ?? '',
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

    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'id': user.id,
      'name': user.name,
      'displayName': user.name,
      'email': user.email,
      'bio': user.bio,
      'location': user.location ?? '',
      'photoUrl': user.photoUrl ?? '',
      'trustScore': user.trustScore,
      'credits': user.credits,
      'verified': user.verified,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await firebaseUser.updateDisplayName(user.name);

    return loadProfile();
  }

  @override
  Future<ProfileData> saveTeachSkill(SkillModel skill) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    final userDoc = _firestore.collection('users').doc(userId);
    final teachSkill = skill.copyWith(teachable: true);

    await userDoc
        .collection('teachSkills')
        .doc(teachSkill.id)
        .set(teachSkill.toMap(), SetOptions(merge: true));

    await _syncSkillSummary(userDoc);
    return loadProfile();
  }

  @override
  Future<ProfileData> deleteTeachSkill(String skillId) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    final userDoc = _firestore.collection('users').doc(userId);
    await userDoc.collection('teachSkills').doc(skillId).delete();
    await _syncSkillSummary(userDoc);
    return loadProfile();
  }

  @override
  Future<ProfileData> saveLearnSkill(SkillModel skill) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    final userDoc = _firestore.collection('users').doc(userId);
    final learnSkill = skill.copyWith(
      learnable: true,
      level: skill.level.clamp(1, 7),
    );

    await userDoc
        .collection('learnSkills')
        .doc(learnSkill.id)
        .set(learnSkill.toMap(), SetOptions(merge: true));

    await _syncSkillSummary(userDoc);
    return loadProfile();
  }

  @override
  Future<ProfileData> deleteLearnSkill(String skillId) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return loadProfile();
    }

    final userDoc = _firestore.collection('users').doc(userId);
    await userDoc.collection('learnSkills').doc(skillId).delete();
    await _syncSkillSummary(userDoc);
    return loadProfile();
  }

  Future<List<SkillModel>> _readSkills(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) {
      return SkillModel.fromMap({'id': doc.id, ...doc.data()});
    }).toList();
  }

  Future<void> _syncSkillSummary(
    DocumentReference<Map<String, dynamic>> userDoc,
  ) async {
    final teachSkills = await _readSkills(userDoc.collection('teachSkills'));
    final learnSkills = await _readSkills(userDoc.collection('learnSkills'));

    await userDoc.set({
      'skills': teachSkills.map((skill) => skill.toMap()).toList(),
      'teachSkillNames': teachSkills
          .map((skill) => skill.name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toList(),
      'learnSkillNames': learnSkills
          .map((skill) => skill.name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
