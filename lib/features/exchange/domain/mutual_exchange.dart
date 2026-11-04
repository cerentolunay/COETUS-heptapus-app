import 'package:cloud_firestore/cloud_firestore.dart';

enum MutualAction { complete, cancel, dispute, remind, expire }

class MutualExchange {
  const MutualExchange({
    required this.participants,
    required this.deposits,
    required this.status,
    this.completionVotes = const [],
    this.cancellationVotes = const [],
    this.completionRequestedAt,
    this.remindedAt,
    this.disputedBy,
    this.disputeReason = '',
  });
  static const reminderDelay = Duration(hours: 24);
  static const responseWindow = Duration(hours: 72);
  final List<String> participants, completionVotes, cancellationVotes;
  final Map<String, int> deposits;
  final String status;
  final DateTime? completionRequestedAt, remindedAt;
  final String? disputedBy;
  final String disputeReason;
  bool get terminal => ['completed', 'cancelled', 'expired'].contains(status);
  bool get waiting =>
      status == 'active' &&
      completionVotes.length == 1 &&
      cancellationVotes.isEmpty &&
      disputedBy == null;
  bool dueForReminder(DateTime now) =>
      waiting &&
      remindedAt == null &&
      completionRequestedAt != null &&
      !now.isBefore(completionRequestedAt!.add(reminderDelay)) &&
      !dueForExpiry(now);
  bool dueForExpiry(DateTime now) =>
      waiting &&
      completionRequestedAt != null &&
      !now.isBefore(completionRequestedAt!.add(responseWindow));
  factory MutualExchange.fromMap(Map<String, dynamic> data) {
    DateTime? date(Object? value) => value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    List<String> list(String key) =>
        (data[key] as List? ?? []).whereType<String>().toList();
    return MutualExchange(
      participants: list('participants'),
      deposits: Map<String, dynamic>.from(
        data['deposits'] as Map? ?? {},
      ).map((k, v) => MapEntry(k, (v as num).toInt())),
      status: data['status'] as String? ?? 'requested',
      completionVotes: list('completionVotes'),
      cancellationVotes: list('cancellationVotes'),
      completionRequestedAt: date(data['completionRequestedAt']),
      remindedAt: date(data['remindedAt']),
      disputedBy: data['disputedBy'] as String?,
      disputeReason: data['disputeReason'] as String? ?? '',
    );
  }
}
