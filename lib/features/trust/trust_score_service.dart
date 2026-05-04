import 'package:coetus/features/trust/trust_activity_summary.dart';
import 'package:coetus/features/trust/trust_score_calculator.dart';

class TrustScoreService {
  const TrustScoreService();

  int calculateFromActivity(TrustActivitySummary activity) {
    return TrustScoreCalculator.calculateTrustScore(
      completedSessionCount: activity.completedSessionCount,
      verificationCount: activity.verificationCount,
      cancelledSessionCount: activity.cancelledSessionCount,
    );
  }

  int calculateFromSessionStatuses({
    required Iterable<String> sessionStatuses,
    required int verificationCount,
  }) {
    final activity = TrustActivitySummary.fromSessionStatuses(
      sessionStatuses: sessionStatuses,
      verificationCount: verificationCount,
    );

    return calculateFromActivity(activity);
  }
}
