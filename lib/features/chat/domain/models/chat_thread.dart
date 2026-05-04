import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final String sessionId;
  final String matchId;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatThread({
    required this.id,
    required this.sessionId,
    required this.matchId,
    required this.participants,
    this.lastMessage = '',
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatThread.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ChatThread.fromMap({'id': doc.id, ...?doc.data()});
  }

  factory ChatThread.fromMap(Map<String, dynamic> map) {
    return ChatThread(
      id: map['id'] as String? ?? '',
      sessionId: map['sessionId'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      participants: _readStringList(map['participants']),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: _readDateTime(map['lastMessageAt']),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  ChatThread copyWith({
    String? id,
    String? sessionId,
    String? matchId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      matchId: matchId ?? this.matchId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'matchId': matchId,
      'participants': participants,
      'lastMessage': lastMessage,
      if (lastMessageAt != null)
        'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

List<String> _readStringList(Object? value) {
  if (value is! List) return [];
  return value.whereType<String>().toList();
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
