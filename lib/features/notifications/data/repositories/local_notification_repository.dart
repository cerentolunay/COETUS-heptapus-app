import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class LocalNotificationRepository implements NotificationRepository {
  const LocalNotificationRepository();

  @override
  Stream<List<AppNotification>> streamUserNotifications(String userId) {
    return Stream.value(const []);
  }

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}
}
