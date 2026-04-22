import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final snapshot = await _firestore.collection('users').doc(firebaseUser.uid).get();
    final data = snapshot.data();

    if (data == null) {
      return AppUser(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        bio: '',
      );
    }

    return AppUser.fromMap({
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? data['email'] ?? '',
      ...data,
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase user could not be created.');
    }

    return _upsertUserProfile(
      user: firebaseUser,
      fallbackName: firebaseUser.displayName ?? email.split('@').first,
    );
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase user could not be created.');
    }

    await firebaseUser.updateDisplayName(fullName.trim());

    return _upsertUserProfile(
      user: firebaseUser,
      fallbackName: fullName.trim(),
      bio: 'Ready to exchange skills',
    );
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<AppUser> _upsertUserProfile({
    required User user,
    required String fallbackName,
    String bio = 'Skill swapping enthusiast',
  }) async {
    final profile = AppUser(
      id: user.uid,
      name: user.displayName ?? fallbackName,
      email: user.email ?? '',
      bio: bio,
      trustScore: 0,
      credits: 0,
      verified: false,
    );

    await _firestore.collection('users').doc(user.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );

    return profile;
  }
}
