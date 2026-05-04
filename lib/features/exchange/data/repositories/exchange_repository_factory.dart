import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/exchange_repository.dart';
import 'firebase_exchange_repository.dart';
import 'local_exchange_repository.dart';

class ExchangeRepositoryFactory {
  static ExchangeRepository create() {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseExchangeRepository();
    }

    return const LocalExchangeRepository();
  }
}
