import 'package:coetus/features/profile/domain/models/skill_model.dart';
import 'package:coetus/features/skill_graph/skill_graph_edge.dart';
import 'package:coetus/features/skill_graph/skill_recommendation.dart';

class SkillGraphService {
  const SkillGraphService({required List<SkillGraphEdge> edges})
      : _edges = edges;

  final List<SkillGraphEdge> _edges;

  List<SkillRecommendation> recommendRelatedSkills({
    required List<SkillModel> userSkills,
  }) {
    final ownedSkillIds = userSkills.map((skill) => skill.id).toSet();
    final scoresBySkillId = <String, double>{};

    for (final skill in userSkills) {
      for (final edge in _edges) {
        if (edge.fromSkillId != skill.id) continue;
        if (ownedSkillIds.contains(edge.toSkillId)) continue;

        final score = _clamp01(skill.level * edge.relationStrength / 7);
        final previousScore = scoresBySkillId[edge.toSkillId] ?? 0;
        if (score > previousScore) {
          scoresBySkillId[edge.toSkillId] = score;
        }
      }
    }

    final recommendations = scoresBySkillId.entries
        .map(
          (entry) => SkillRecommendation(
            skillId: entry.key,
            score: entry.value,
          ),
        )
        .toList();

    recommendations.sort((first, second) => second.score.compareTo(first.score));
    return recommendations;
  }

  double relatedSkillScore({
    required String fromSkillId,
    required String toSkillId,
  }) {
    for (final edge in _edges) {
      if (edge.fromSkillId == fromSkillId && edge.toSkillId == toSkillId) {
        return _clamp01(edge.relationStrength);
      }
    }

    return 0;
  }

  double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
