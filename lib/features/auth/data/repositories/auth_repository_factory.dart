import 'package:coetus/preview/preview_mode.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/auth_repository.dart';
import 'firebase_auth_repository.dart';
import 'local_auth_repository.dart';

class AuthRepositoryFactory {
  static AuthRepository create() {
    if (!PreviewMode.enabled && Firebase.apps.isNotEmpty) {
      return FirebaseAuthRepository();
    }

    return LocalAuthRepository();
  }
}
