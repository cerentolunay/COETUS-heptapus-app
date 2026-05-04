import 'package:coetus/features/credit/credit_calculator.dart';
import 'package:coetus/features/matching/models/match_candidate.dart';
import 'package:coetus/features/matching/models/match_explanation.dart';
import 'package:coetus/features/matching/utils/matching_score_calculator.dart';
import 'package:coetus/features/profile/domain/models/profile_data.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import 'package:coetus/features/skill_graph/skill_graph_service.dart';

class MatchingService {
  const MatchingService({SkillGraphService? skillGraphService})
      : _skillGraphService = skillGraphService;

  final SkillGraphService? _skillGraphService;

  List<MatchCandidate> getRecommendedMatches({
    required ProfileData currentProfile,
    required List<ProfileData> candidateProfiles,
    Map<String, int> matchExposureCounts = const {},
    bool? availabilityMatches,
    int defaultBaseCredit = 30,
  }) {
    final matches = <MatchCandidate>[];

    for (final candidateProfile in candidateProfiles) {
      if (candidateProfile.user.id == currentProfile.user.id) continue;

      for (final studentSkill in currentProfile.learnSkills) {
        for (final teacherSkill in candidateProfile.teachSkills) {
          final skillMatchType = _skillMatchType(
            teacherSkill: teacherSkill,
            studentSkill: studentSkill,
          );
          if (skillMatchType == null) continue;

          final skillCompatibilityScore = _calculateSkillCompatibilityScore(
            teacherSkill: teacherSkill,
            studentSkill: studentSkill,
            skillMatchType: skillMatchType,
          );
          if (skillCompatibilityScore == 0) continue;

          final skillLevelScore =
              MatchingScoreCalculator.calculateSkillLevelScore(
                teacherLevel: teacherSkill.level,
                studentLevel: studentSkill.level,
              );
          if (skillLevelScore == 0) continue;

          final combinedSkillScore =
              skillLevelScore * skillCompatibilityScore;

          final trustScore = MatchingScoreCalculator.calculatePairTrustScore(
            userTrustScore: currentProfile.user.trustScore,
            partnerTrustScore: candidateProfile.user.trustScore,
          );
          final availabilityScore = availabilityMatches == null
              ? MatchingScoreCalculator.calculateAvailabilityScore(
                  userSlots: currentProfile.availabilitySlots,
                  partnerSlots: candidateProfile.availabilitySlots,
                )
              : (availabilityMatches ? 1.0 : 0.0);
          final profileCompleteness = _calculateProfileCompleteness(
            candidateProfile,
          );
          final fairnessScore = MatchingScoreCalculator.calculateFairnessScore(
            matchExposureCounts[candidateProfile.user.id] ?? 0,
          );
          final matchScore = MatchingScoreCalculator.calculateMatchScore(
            skillLevelScore: combinedSkillScore,
            trustScore: trustScore,
            availabilityScore: availabilityScore,
            profileCompleteness: profileCompleteness,
          );

          matches.add(
            MatchCandidate(
              user: candidateProfile.user,
              teacherSkill: teacherSkill,
              studentSkill: studentSkill,
              partnerLearnSkills: candidateProfile.learnSkills,
              matchScore: matchScore,
              skillLevelScore: combinedSkillScore,
              trustScore: trustScore,
              availabilityScore: availabilityScore,
              profileCompleteness: profileCompleteness,
              fairnessScore: fairnessScore,
              creditsRequired: CreditCalculator.calculateCreditCost(
                baseCredit: defaultBaseCredit,
                teacherLevel: teacherSkill.level,
              ),
              explanation: MatchExplanation(
                skillMatchType: skillMatchType,
                skillCompatibilityScore: skillCompatibilityScore,
                hasAvailabilityOverlap: availabilityScore > 0,
                averageTrustScore: trustScore,
                profileCompleteness: profileCompleteness,
              ),
            ),
          );
        }
      }
    }

    matches.sort(
      (first, second) => second.matchScore.compareTo(first.matchScore),
    );
    return matches;
  }

  double _calculateSkillCompatibilityScore({
    required SkillModel teacherSkill,
    required SkillModel studentSkill,
    required SkillMatchType skillMatchType,
  }) {
    if (skillMatchType == SkillMatchType.exact) return 1;

    return _skillGraphService?.relatedSkillScore(
          fromSkillId: teacherSkill.id,
          toSkillId: studentSkill.id,
        ) ??
        0;
  }

  SkillMatchType? _skillMatchType({
    required SkillModel teacherSkill,
    required SkillModel studentSkill,
  }) {
    if (_isSameSkill(studentSkill, teacherSkill)) {
      return SkillMatchType.exact;
    }

    final relatedScore = _skillGraphService?.relatedSkillScore(
          fromSkillId: teacherSkill.id,
          toSkillId: studentSkill.id,
        ) ??
        0;

    if (relatedScore > 0) {
      return SkillMatchType.related;
    }

    return null;
  }

  bool _isSameSkill(SkillModel first, SkillModel second) {
    if (first.id.isNotEmpty && second.id.isNotEmpty) {
      return first.id == second.id;
    }

    return first.name.trim().toLowerCase() == second.name.trim().toLowerCase();
  }

  double _calculateProfileCompleteness(ProfileData profile) {
    return MatchingScoreCalculator.calculateProfileCompleteness(
      hasName: profile.user.name.trim().isNotEmpty,
      hasBio: profile.user.bio.trim().isNotEmpty,
      hasTeachSkills: profile.teachSkills.isNotEmpty,
      hasLearnSkills: profile.learnSkills.isNotEmpty,
      verified: profile.user.verified,
    );
  }
}
