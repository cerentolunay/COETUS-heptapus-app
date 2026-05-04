class TrustActivitySummary {
  final int completedSessionCount;
  final int verificationCount;
  final int cancelledSessionCount;

  const TrustActivitySummary({
    required this.completedSessionCount,
    required this.verificationCount,
    required this.cancelledSessionCount,
  });

  factory TrustActivitySummary.fromSessionStatuses({
    required Iterable<String> sessionStatuses,
    required int verificationCount,
  }) {
    var completedCount = 0;
    var cancelledCount = 0;

    for (final status in sessionStatuses) {
      final normalizedStatus = status.trim().toLowerCase();
      if (normalizedStatus == 'completed') {
        completedCount += 1;
      } else if (normalizedStatus == 'cancelled' ||
          normalizedStatus == 'canceled') {
        cancelledCount += 1;
      }
    }

    return TrustActivitySummary(
      completedSessionCount: completedCount,
      verificationCount: verificationCount,
      cancelledSessionCount: cancelledCount,
    );
  }
}
