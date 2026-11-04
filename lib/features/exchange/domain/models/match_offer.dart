import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchOfferStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  static MatchOfferStatus fromValue(String? value) {
    return MatchOfferStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MatchOfferStatus.pending,
    );
  }
}

class MatchOffer {
  final String id;
  final String requesterId;
  final String receiverId;
  final String requesterName;
  final String receiverName;
  final List<String> participants;
  final String skill;
  final Map<String, int> deposits;
  final int credits;
  final MatchOfferStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MatchOffer({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    this.requesterName = '',
    this.receiverName = '',
    required this.participants,
    required this.skill,
    required this.credits,
    this.deposits = const {},
    this.status = MatchOfferStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  factory MatchOffer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MatchOffer.fromMap({'id': doc.id, ...?doc.data()});
  }

  factory MatchOffer.fromMap(Map<String, dynamic> map) {
    return MatchOffer(
      id: map['id'] as String? ?? '',
      requesterId:
          map['requesterId'] as String? ?? map['initiatorId'] as String? ?? '',
      receiverId:
          map['receiverId'] as String? ?? map['recipientId'] as String? ?? '',
      requesterName:
          map['requesterName'] as String? ??
          _readStringMap(map['participantNames'])[map['requesterId']] ??
          '',
      receiverName:
          map['receiverName'] as String? ??
          _readStringMap(map['participantNames'])[map['receiverId']] ??
          '',
      participants: _readStringList(map['participants']),
      skill:
          map['skill'] as String? ??
          map['skillName'] as String? ??
          map['skillId'] as String? ??
          '',
      deposits: Map<String, dynamic>.from(
        map['deposits'] as Map? ?? {},
      ).map((k, v) => MapEntry(k, (v as num).toInt())),
      credits: _readInt(map['credits']),
      status: MatchOfferStatus.fromValue(map['status'] as String?),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  MatchOffer copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    String? requesterName,
    String? receiverName,
    List<String>? participants,
    String? skill,
    int? credits,
    MatchOfferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatchOffer(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      requesterName: requesterName ?? this.requesterName,
      receiverName: receiverName ?? this.receiverName,
      participants: participants ?? this.participants,
      skill: skill ?? this.skill,
      deposits: deposits,
      credits: credits ?? this.credits,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'requesterName': requesterName,
      'receiverName': receiverName,
      'participants': participants,
      'skill': skill,
      if (deposits.isNotEmpty) 'deposits': deposits,
      'credits': credits,
      'status': status.name,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

List<String> _readStringList(Object? value) {
  if (value is! List) return [];
  return value.whereType<String>().toList();
}

Map<String, String> _readStringMap(Object? value) {
  if (value is! Map) return {};
  return value.map(
    (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
  );
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
