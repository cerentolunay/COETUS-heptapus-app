import 'package:cloud_firestore/cloud_firestore.dart';

enum ExchangeSessionStatus {
  requested,
  active,
  scheduled,
  completed,
  cancelled;

  static ExchangeSessionStatus fromValue(String? value) {
    return ExchangeSessionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ExchangeSessionStatus.requested,
    );
  }
}

class ExchangeSession {
  final String id;
  final String matchId;
  final String teacherId;
  final String studentId;
  final List<String> participants;
  final String skill;
  final int credits;
  final ExchangeSessionStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExchangeSession({
    required this.id,
    required this.matchId,
    required this.teacherId,
    required this.studentId,
    required this.participants,
    required this.skill,
    required this.credits,
    this.status = ExchangeSessionStatus.requested,
    this.createdAt,
    this.updatedAt,
  });

  factory ExchangeSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ExchangeSession.fromMap({'id': doc.id, ...?doc.data()});
  }

  factory ExchangeSession.fromMap(Map<String, dynamic> map) {
    return ExchangeSession(
      id: map['id'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      participants: _readStringList(map['participants']),
      skill:
          map['skill'] as String? ??
          map['skillName'] as String? ??
          map['skillId'] as String? ??
          '',
      credits: _readInt(map['credits']),
      status: ExchangeSessionStatus.fromValue(map['status'] as String?),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  ExchangeSession copyWith({
    String? id,
    String? matchId,
    String? teacherId,
    String? studentId,
    List<String>? participants,
    String? skill,
    int? credits,
    ExchangeSessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExchangeSession(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
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
      'matchId': matchId,
      'teacherId': teacherId,
      'studentId': studentId,
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
