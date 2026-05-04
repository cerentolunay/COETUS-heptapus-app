class TrustScoreCalculator {
  const TrustScoreCalculator._();

  static int calculateTrustScore({
    required int completedSessionCount,
    required int verificationCount,
    required int cancelledSessionCount,
  }) {
    final sessionScore = (completedSessionCount * 2).clamp(0, 40).toInt();
    final verificationScore = (verificationCount * 10).clamp(0, 30).toInt();
    final cancellationPenalty = cancelledSessionCount * 5;

    final score = sessionScore + verificationScore - cancellationPenalty;

    return score.clamp(0, 100).toInt();
  }
}
