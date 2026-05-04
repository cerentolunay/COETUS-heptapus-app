class SkillGraphEdge {
  final String fromSkillId;
  final String toSkillId;
  final double relationStrength;

  const SkillGraphEdge({
    required this.fromSkillId,
    required this.toSkillId,
    required this.relationStrength,
  });
}
