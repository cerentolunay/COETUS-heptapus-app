import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  static const Duration _requestTimeout = Duration(seconds: 15);

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final snapshot = await _firestore
      .collection('users')
      .doc(firebaseUser.uid)
      .get()
      .timeout(_requestTimeout);
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
    final credential = await _firebaseAuth
        .signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(_requestTimeout);

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase user could not be created.');
    }

    final profile = _buildProfile(
      user: firebaseUser,
      fallbackName: firebaseUser.displayName ?? email.split('@').first,
    );
    _syncUserProfile(profile);
    return profile;
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(_requestTimeout);

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase user could not be created.');
    }

    await firebaseUser.updateDisplayName(fullName.trim()).timeout(_requestTimeout);

    final profile = _buildProfile(
      user: firebaseUser,
      fallbackName: fullName.trim(),
      bio: 'Ready to exchange skills',
    );
    _syncUserProfile(profile);
    return profile;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: <String>['email'],
    );

    final googleUser = await googleSignIn.signIn().timeout(_requestTimeout);
    if (googleUser == null) {
      throw StateError('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication.timeout(_requestTimeout);
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCredential = await _firebaseAuth
        .signInWithCredential(credential)
        .timeout(_requestTimeout);

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase user could not be created.');
    }

    final profile = _buildProfile(
      user: firebaseUser,
      fallbackName: firebaseUser.displayName ?? 'Google User',
      bio: 'Ready to exchange skills',
    );
    _syncUserProfile(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut().timeout(_requestTimeout);
  }

  AppUser _buildProfile({
    required User user,
    required String fallbackName,
    String bio = 'Skill swapping enthusiast',
  }) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? fallbackName,
      email: user.email ?? '',
      bio: bio,
      trustScore: 0,
      credits: 0,
      verified: false,
    );
  }

  void _syncUserProfile(AppUser profile) {
    unawaited(() async {
      try {
        await _firestore
            .collection('users')
            .doc(profile.id)
            .set(
              profile.toMap(),
              SetOptions(merge: true),
            )
            .timeout(_requestTimeout);
      } on TimeoutException {
        // Firestore is optional for unblocking auth; retry can happen later.
      } catch (_) {
        // Ignore background profile sync failures.
      }
    }());
  }
}
