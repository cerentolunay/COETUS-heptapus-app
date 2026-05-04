import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:coetus/features/matching/models/match_explanation.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';

class MatchCandidate {
  final AppUser user;
  final SkillModel teacherSkill;
  final SkillModel studentSkill;
  final List<SkillModel> partnerLearnSkills;
  final double matchScore;
  final double skillLevelScore;
  final double trustScore;
  final double availabilityScore;
  final double profileCompleteness;
  final double fairnessScore;
  final int creditsRequired;
  final MatchExplanation explanation;

  const MatchCandidate({
    required this.user,
    required this.teacherSkill,
    required this.studentSkill,
    this.partnerLearnSkills = const [],
    required this.matchScore,
    required this.skillLevelScore,
    required this.trustScore,
    required this.availabilityScore,
    required this.profileCompleteness,
    required this.fairnessScore,
    required this.creditsRequired,
    required this.explanation,
  });
}
