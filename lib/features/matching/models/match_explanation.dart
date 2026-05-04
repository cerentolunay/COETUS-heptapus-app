enum SkillMatchType {
  exact,
  related,
}

class MatchExplanation {
  final SkillMatchType skillMatchType;
  final double skillCompatibilityScore;
  final bool hasAvailabilityOverlap;
  final double averageTrustScore;
  final double profileCompleteness;

  const MatchExplanation({
    required this.skillMatchType,
    required this.skillCompatibilityScore,
    required this.hasAvailabilityOverlap,
    required this.averageTrustScore,
    required this.profileCompleteness,
  });
}
