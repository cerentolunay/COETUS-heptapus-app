import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType {
  text,
  system,
  escrow,
  schedule;

  static ChatMessageType fromValue(String? value) {
    return ChatMessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ChatMessageType.text,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final ChatMessageType type;
  final List<String> readBy;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = ChatMessageType.text,
    this.readBy = const [],
    this.createdAt,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ChatMessage.fromMap({'id': doc.id, ...?doc.data()});
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      type: ChatMessageType.fromValue(map['type'] as String?),
      readBy: _readStringList(map['readBy']),
      createdAt: _readDateTime(map['createdAt']),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    ChatMessageType? type,
    List<String>? readBy,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'readBy': readBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
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
