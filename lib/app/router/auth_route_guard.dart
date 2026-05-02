import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthRouteGuard extends ChangeNotifier {
  AuthRouteGuard({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth,
      _firestore = firestore {
    if (!isEnabled) {
      return;
    }

    _currentUser = _auth.currentUser;
    _authSubscription = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;

  bool get isEnabled => Firebase.apps.isNotEmpty;
  bool get isSignedIn => _currentUser != null;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<bool> isProfileCompleted() async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }

    final snapshot = await _db.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    if (data == null) {
      return false;
    }

    final explicitValue = data['profileCompleted'];
    if (explicitValue is bool) {
      return explicitValue;
    }

    final name = data['name'] as String? ?? user.displayName ?? '';
    final bio = data['bio'] as String? ?? '';
    return name.trim().isNotEmpty && bio.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
