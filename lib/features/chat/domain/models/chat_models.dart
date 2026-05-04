import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, List<String>> participantSkills;
  final String? matchId;
  final String? sessionId;
  final String skillName;
  final String lastMessage;
  final String lastSenderId;
  final int unreadCount;
  final int credits;
  final String status;
  final DateTime? updatedAt;

  const ChatThread({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantSkills,
    this.matchId,
    this.sessionId,
    required this.skillName,
    required this.lastMessage,
    required this.lastSenderId,
    required this.unreadCount,
    required this.credits,
    required this.status,
    required this.updatedAt,
  });

  String otherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
  }

  String otherUserName(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantNames[otherId]?.trim().isNotEmpty == true
        ? participantNames[otherId]!
        : 'Kullanici';
  }

  List<String> otherUserSkills(String currentUserId) {
    return participantSkills[otherUserId(currentUserId)] ?? const [];
  }

  factory ChatThread.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatThread(
      id: doc.id,
      participants: _readStringList(data['participants']),
      participantNames: _readStringMap(data['participantNames']),
      participantSkills: _readStringListMap(data['participantSkills']),
      matchId: data['matchId'] as String?,
      sessionId: data['sessionId'] as String?,
      skillName: data['skillName'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderId: data['lastSenderId'] as String? ?? '',
      unreadCount: _readInt(data['unreadCount']),
      credits: _readInt(data['credits']),
      status: data['status'] as String? ?? 'active',
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  factory ChatMessage.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Kullanici',
      text: data['text'] as String? ?? '',
      type: data['type'] as String? ?? 'text',
      createdAt: _readDateTime(data['createdAt']),
    );
  }
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

Map<String, String> _readStringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
  );
}

Map<String, List<String>> _readStringListMap(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, item) => MapEntry(key.toString(), _readStringList(item)),
  );
}
