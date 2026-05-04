import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<AppNotification>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList();
          notifications.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(0);
            final bDate = b.createdAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          return notifications;
        });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).set({
      'read': true,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {'read': true}, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
