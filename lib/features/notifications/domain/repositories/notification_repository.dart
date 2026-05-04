import '../models/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> streamUserNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
