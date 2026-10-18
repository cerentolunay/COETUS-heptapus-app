import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/services/profile_completion_service.dart';

/// Profile completion notifier - dinler auth state ve profile completion status'ü
/// GoRouter'ı trigger etmek amacıyla hem auth hem profile değişiklikleri için
class ProfileCompletionNotifier extends ChangeNotifier {
  final ProfileCompletionService _profileCompletionService;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription? _authSubscription;
  StreamSubscription? _profileStreamSubscription;

  bool _isProfileCompleted = false;
  bool _isLoading = true;
  bool _isSignedIn = false;

  bool get isProfileCompleted => _isProfileCompleted;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _isSignedIn;

  ProfileCompletionNotifier({
    ProfileCompletionService? profileCompletionService,
    FirebaseAuth? firebaseAuth,
  }) : _profileCompletionService =
           profileCompletionService ?? ProfileCompletionService(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    // Auth state değişikliklerini dinle
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      _isSignedIn = user != null;
      if (user != null) {
        _setupProfileStream();
      } else {
        // Logout durumu
        _profileStreamSubscription?.cancel();
        _profileStreamSubscription = null;
        _isProfileCompleted = false;
        _isLoading = false;
        notifyListeners();
      }
    });

    // İlk check
    _setupProfileStream();
  }

  /// Set up real-time listener for profile completion changes from Firestore
  void _setupProfileStream() {
    _profileStreamSubscription?.cancel();

    if (_firebaseAuth.currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    _profileStreamSubscription = _profileCompletionService
        .profileCompletionStream()
        .listen(
          (isCompleted) {
            _isProfileCompleted = isCompleted;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            if (kDebugMode) {
              debugPrint('Profile completion stream could not be read.');
            }
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Profile completion'ı manuel olarak set et (kaydet sonrası)
  void setProfileCompleted(bool completed) {
    _isProfileCompleted = completed;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileStreamSubscription?.cancel();
    super.dispose();
  }
}
