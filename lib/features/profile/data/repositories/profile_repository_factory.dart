import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/profile_repository.dart';
import 'firebase_profile_repository.dart';
import 'local_profile_repository.dart';

class ProfileRepositoryFactory {
  static ProfileRepository create() {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseProfileRepository();
    }

    return LocalProfileRepository();
  }
}
