import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/notification_repository.dart';
import 'firebase_notification_repository.dart';
import 'local_notification_repository.dart';

class NotificationRepositoryFactory {
  static NotificationRepository create() {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseNotificationRepository();
    }

    return const LocalNotificationRepository();
  }
}
