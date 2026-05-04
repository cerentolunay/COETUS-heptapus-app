class MatchingScoreCalculator {
  const MatchingScoreCalculator._();

  static double calculateSkillLevelScore({
    required int teacherLevel,
    required int studentLevel,
  }) {
    final levelGap = teacherLevel - studentLevel;
    if (levelGap < 2) return 0;

    return _clamp01(levelGap / 5);
  }

  static double calculateFairnessScore(int matchExposureCount) {
    if (matchExposureCount <= 0) return 1;
    return 1 / (1 + matchExposureCount);
  }

  static double calculateAvailabilityScore({
    required List<String> userSlots,
    required List<String> partnerSlots,
  }) {
    if (userSlots.isEmpty || partnerSlots.isEmpty) return 0;

    final normalizedUserSlots = userSlots.map(_normalizeSlot).toSet();
    final hasOverlap = partnerSlots
        .map(_normalizeSlot)
        .any((slot) => normalizedUserSlots.contains(slot));

    return hasOverlap ? 1 : 0;
  }

  static double calculateMatchScore({
    required double skillLevelScore,
    required double trustScore,
    required double availabilityScore,
    required double profileCompleteness,
  }) {
    return _clamp01(
      (0.40 * _clamp01(skillLevelScore)) +
          (0.30 * _clamp01(trustScore)) +
          (0.20 * _clamp01(availabilityScore)) +
          (0.10 * _clamp01(profileCompleteness)),
    );
  }

  static double normalizeTrustScore(int trustScore) {
    return _clamp01(trustScore / 100);
  }

  static double calculatePairTrustScore({
    required int userTrustScore,
    required int partnerTrustScore,
  }) {
    return _clamp01(((userTrustScore + partnerTrustScore) / 2) / 100);
  }

  static double calculateProfileCompleteness({
    required bool hasName,
    required bool hasBio,
    required bool hasTeachSkills,
    required bool hasLearnSkills,
    required bool verified,
  }) {
    final completedFields = [
      hasName,
      hasBio,
      hasTeachSkills,
      hasLearnSkills,
      verified,
    ].where((isComplete) => isComplete).length;

    return completedFields / 5;
  }

  static double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  static String _normalizeSlot(String slot) {
    return slot.trim().toLowerCase();
  }
}
