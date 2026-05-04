import 'package:coetus/features/credit/escrow_status.dart';

class EscrowRecord {
  final String id;
  final String studentId;
  final String teacherId;
  final String skillId;
  final int credits;
  final EscrowStatus status;

  const EscrowRecord({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.skillId,
    required this.credits,
    this.status = EscrowStatus.pending,
  });

  EscrowRecord copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? skillId,
    int? credits,
    EscrowStatus? status,
  }) {
    return EscrowRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      skillId: skillId ?? this.skillId,
      credits: credits ?? this.credits,
      status: status ?? this.status,
    );
  }
}
