import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Auth state changes'i dinleyen ve GoRouter'ı refresh etmesi için
/// ValueNotifier'a event gönderen notifier
class AuthStateNotifier extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;

  AuthStateNotifier({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    // Auth state changes'i dinle ve bu notifier'ı update et
    _firebaseAuth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  /// Mevcut auth durumu
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Mevcut kullanıcı
  User? get currentUser => _firebaseAuth.currentUser;
}
