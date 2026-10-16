import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  offerReceived,
  offerAccepted,
  offerRejected,
  sessionStarted,
  newMessage,
  verificationApproved,
  communityActivity,
  tokenSupport,
  learningCompleted,
  learningRefund;

  String get value {
    switch (this) {
      case AppNotificationType.communityActivity:
        return 'community_activity';
      case AppNotificationType.tokenSupport:
        return 'token_support';
      case AppNotificationType.learningCompleted:
        return 'learning_completed';
      case AppNotificationType.learningRefund:
        return 'learning_refund';
      case AppNotificationType.offerReceived:
        return 'offer_received';
      case AppNotificationType.offerAccepted:
        return 'offer_accepted';
      case AppNotificationType.offerRejected:
        return 'offer_rejected';
      case AppNotificationType.sessionStarted:
        return 'session_started';
      case AppNotificationType.newMessage:
        return 'new_message';
      case AppNotificationType.verificationApproved:
        return 'verification_approved';
    }
  }

  static AppNotificationType fromValue(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.value == value || type.name == value,
      orElse: () => AppNotificationType.offerReceived,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String senderId;
  final AppNotificationType type;
  final String title;
  final String message;
  final String targetRoute;
  final String targetId;
  final String? matchId;
  final String? sessionId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.message,
    required this.targetRoute,
    required this.targetId,
    this.matchId,
    this.sessionId,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AppNotification.fromMap({'id': doc.id, ...?doc.data()});
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      type: AppNotificationType.fromValue(map['type'] as String?),
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      targetRoute: map['targetRoute'] as String? ?? '',
      targetId: map['targetId'] as String? ?? '',
      matchId: map['matchId'] as String?,
      sessionId: map['sessionId'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: _readDateTime(map['createdAt']),
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? senderId,
    AppNotificationType? type,
    String? title,
    String? message,
    String? targetRoute,
    String? targetId,
    String? matchId,
    String? sessionId,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      targetRoute: targetRoute ?? this.targetRoute,
      targetId: targetId ?? this.targetId,
      matchId: matchId ?? this.matchId,
      sessionId: sessionId ?? this.sessionId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'senderId': senderId,
      'type': type.value,
      'title': title,
      'message': message,
      'targetRoute': targetRoute,
      'targetId': targetId,
      'matchId': matchId,
      'sessionId': sessionId,
      'read': read,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
