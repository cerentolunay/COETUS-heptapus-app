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
  final List<String> participants;
  final String skill;
  final int credits;
  final MatchOfferStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MatchOffer({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.participants,
    required this.skill,
    required this.credits,
    this.status = MatchOfferStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  factory MatchOffer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MatchOffer.fromMap({'id': doc.id, ...?doc.data()});
  }

  factory MatchOffer.fromMap(Map<String, dynamic> map) {
    return MatchOffer(
      id: map['id'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      participants: _readStringList(map['participants']),
      skill:
          map['skill'] as String? ??
          map['skillName'] as String? ??
          map['skillId'] as String? ??
          '',
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
      participants: participants ?? this.participants,
      skill: skill ?? this.skill,
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
      'participants': participants,
      'skill': skill,
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
