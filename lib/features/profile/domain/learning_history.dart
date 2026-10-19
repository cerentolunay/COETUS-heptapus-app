import '../../exchange/domain/models/exchange_session.dart';

enum LearningHistoryRole { taught, learned }

DateTime? sessionHistoryDate(ExchangeSession session) =>
    session.updatedAt ?? session.createdAt;

List<ExchangeSession> completedLearningHistory(
  Iterable<ExchangeSession> sessions,
  String userId,
  LearningHistoryRole role,
) {
  final result = sessions
      .where(
        (session) =>
            userId.isNotEmpty &&
            session.status == ExchangeSessionStatus.completed &&
            session.participants.contains(userId) &&
            (role == LearningHistoryRole.taught
                ? session.teacherId == userId
                : session.studentId == userId),
      )
      .toList();
  result.sort((a, b) {
    final aDate = sessionHistoryDate(a), bDate = sessionHistoryDate(b);
    if (aDate == null && bDate != null) return 1;
    if (bDate == null && aDate != null) return -1;
    final dateOrder = aDate == null ? 0 : bDate!.compareTo(aDate);
    return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
  });
  return result;
}
