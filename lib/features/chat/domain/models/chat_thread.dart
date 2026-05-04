import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final String sessionId;
  final String matchId;
  final List<String> participants;
  final String skillName;
  final String lastMessage;
  final String lastSenderId;
  final int credits;
  final String status;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatThread({
    required this.id,
    required this.sessionId,
    required this.matchId,
    required this.participants,
    this.skillName = '',
    this.lastMessage = '',
    this.lastSenderId = '',
    this.credits = 0,
    this.status = 'active',
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ChatThread.fromMap({'id': doc.id, ...?doc.data()});
  }

  factory ChatThread.fromMap(Map<String, dynamic> map) {
    return ChatThread(
      id: map['id'] as String? ?? '',
      sessionId: map['sessionId'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      participants: _readStringList(map['participants']),
      skillName: map['skillName'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastSenderId: map['lastSenderId'] as String? ?? '',
      credits: _readInt(map['credits']),
      status: map['status'] as String? ?? 'active',
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
    String? skillName,
    String? lastMessage,
    String? lastSenderId,
    int? credits,
    String? status,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      matchId: matchId ?? this.matchId,
      participants: participants ?? this.participants,
      skillName: skillName ?? this.skillName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      credits: credits ?? this.credits,
      status: status ?? this.status,
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
      'skillName': skillName,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'credits': credits,
      'status': status,
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

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
