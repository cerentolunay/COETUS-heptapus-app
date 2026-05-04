import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:coetus/features/credit/credit_calculator.dart';
import 'package:coetus/features/credit/escrow_record.dart';
import 'package:coetus/features/credit/escrow_service.dart';
import 'package:coetus/features/credit/escrow_status.dart';
import 'package:coetus/features/matching/models/match_explanation.dart';
import 'package:coetus/features/matching/services/matching_service.dart';
import 'package:coetus/features/matching/utils/matching_score_calculator.dart';
import 'package:coetus/features/profile/domain/models/profile_data.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import 'package:coetus/features/skill_graph/skill_graph_edge.dart';
import 'package:coetus/features/skill_graph/skill_graph_service.dart';
import 'package:coetus/features/trust/trust_activity_summary.dart';
import 'package:coetus/features/trust/trust_score_calculator.dart';
import 'package:coetus/features/trust/trust_score_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrustScoreCalculator', () {
    test(
      'calculates trust score with session, verification, and cancellation inputs',
      () {
        final score = TrustScoreCalculator.calculateTrustScore(
          completedSessionCount: 12,
          verificationCount: 2,
          cancelledSessionCount: 1,
        );

        expect(score, 39);
      },
    );

    test('clamps trust score to the 0-100 range', () {
      expect(
        TrustScoreCalculator.calculateTrustScore(
          completedSessionCount: 0,
          verificationCount: 0,
          cancelledSessionCount: 10,
        ),
        0,
      );
    });
  });

  group('TrustScoreService', () {
    test('calculates trust score from session statuses and verification count',
        () {
      final score = const TrustScoreService().calculateFromSessionStatuses(
        sessionStatuses: const [
          'completed',
          'completed',
          'cancelled',
          'scheduled',
        ],
        verificationCount: 2,
      );

      expect(score, 19);
    });

    test('summarizes completed and cancelled session activity', () {
      final activity = TrustActivitySummary.fromSessionStatuses(
        sessionStatuses: const ['completed', 'canceled', 'cancelled'],
        verificationCount: 1,
      );

      expect(activity.completedSessionCount, 1);
      expect(activity.cancelledSessionCount, 2);
      expect(activity.verificationCount, 1);
    });
  });

  group('CreditCalculator', () {
    test('calculates credit cost from base credit and teacher level', () {
      final cost = CreditCalculator.calculateCreditCost(
        baseCredit: 30,
        teacherLevel: 6,
      );

      expect(cost, 60);
    });
  });

  group('EscrowService', () {
    const escrow = EscrowRecord(
      id: 'escrow-1',
      studentId: 'student-1',
      teacherId: 'teacher-1',
      skillId: 'spanish',
      credits: 60,
    );

    test('moves credits from pending to locked to completed', () {
      final service = const EscrowService();

      final locked = service.lockCredits(escrow);
      final completed = service.completeSession(locked);

      expect(locked.status, EscrowStatus.locked);
      expect(completed.status, EscrowStatus.completed);
    });

    test('rejects completing an escrow before credits are locked', () {
      expect(
        () => const EscrowService().completeSession(escrow),
        throwsStateError,
      );
    });
  });

  group('MatchingScoreCalculator', () {
    test('calculates skill level score from teacher and student level gap', () {
      final score = MatchingScoreCalculator.calculateSkillLevelScore(
        teacherLevel: 6,
        studentLevel: 2,
      );

      expect(score, 0.8);
    });

    test('rejects matches with less than two levels of skill gap', () {
      final score = MatchingScoreCalculator.calculateSkillLevelScore(
        teacherLevel: 3,
        studentLevel: 2,
      );

      expect(score, 0);
    });

    test('reduces fairness score as exposure count increases', () {
      expect(MatchingScoreCalculator.calculateFairnessScore(0), 1);
      expect(MatchingScoreCalculator.calculateFairnessScore(3), 0.25);
    });

    test('detects availability overlap between normalized slots', () {
      final score = MatchingScoreCalculator.calculateAvailabilityScore(
        userSlots: const ['Monday-Evening'],
        partnerSlots: const [' monday-evening '],
      );

      expect(score, 1);
    });

    test('calculates normalized pair trust score from both users', () {
      final score = MatchingScoreCalculator.calculatePairTrustScore(
        userTrustScore: 80,
        partnerTrustScore: 60,
      );

      expect(score, 0.7);
    });
  });

  group('MatchingService', () {
    test('returns matching candidates sorted by match score', () {
      const currentProfile = ProfileData(
        user: AppUser(
          id: 'current',
          name: 'Current User',
          email: 'current@example.com',
          bio: 'Learning Spanish',
        ),
        teachSkills: [],
        learnSkills: [SkillModel(id: 'spanish', name: 'Spanish', level: 1)],
      );

      const candidates = [
        ProfileData(
          user: AppUser(
            id: 'strong-teacher',
            name: 'Strong Teacher',
            email: 'strong@example.com',
            bio: 'Experienced teacher',
            trustScore: 90,
            verified: true,
          ),
          teachSkills: [SkillModel(id: 'spanish', name: 'Spanish', level: 7)],
          learnSkills: [SkillModel(id: 'guitar', name: 'Guitar', level: 1)],
        ),
        ProfileData(
          user: AppUser(
            id: 'new-teacher',
            name: 'New Teacher',
            email: 'new@example.com',
            bio: '',
            trustScore: 20,
          ),
          teachSkills: [SkillModel(id: 'spanish', name: 'Spanish', level: 3)],
          learnSkills: [],
        ),
      ];

      final matches = const MatchingService().getRecommendedMatches(
        currentProfile: currentProfile,
        candidateProfiles: candidates,
      );

      expect(matches, hasLength(2));
      expect(matches.first.user.id, 'strong-teacher');
      expect(matches.first.creditsRequired, 70);
    });

    test('can match related skills when skill graph service is provided', () {
      const currentProfile = ProfileData(
        user: AppUser(
          id: 'current',
          name: 'Current User',
          email: 'current@example.com',
          bio: 'Learning music theory',
          trustScore: 80,
        ),
        teachSkills: [],
        learnSkills: [
          SkillModel(id: 'music-theory', name: 'Music Theory', level: 1),
        ],
        availabilitySlots: ['monday-evening'],
      );

      const candidates = [
        ProfileData(
          user: AppUser(
            id: 'guitar-teacher',
            name: 'Guitar Teacher',
            email: 'guitar@example.com',
            bio: 'Guitar teacher',
            trustScore: 80,
          ),
          teachSkills: [
            SkillModel(id: 'guitar', name: 'Guitar', level: 6),
          ],
          learnSkills: [],
          availabilitySlots: ['monday-evening'],
        ),
      ];

      final matches = const MatchingService(
        skillGraphService: SkillGraphService(
          edges: [
            SkillGraphEdge(
              fromSkillId: 'guitar',
              toSkillId: 'music-theory',
              relationStrength: 0.8,
            ),
          ],
        ),
      ).getRecommendedMatches(
        currentProfile: currentProfile,
        candidateProfiles: candidates,
      );

      expect(matches, hasLength(1));
      expect(matches.first.skillLevelScore, 0.8);
      expect(matches.first.explanation.skillMatchType, SkillMatchType.related);
      expect(matches.first.explanation.hasAvailabilityOverlap, isTrue);
      expect(matches.first.explanation.averageTrustScore, 0.8);
    });
  });

  group('SkillGraphService', () {
    test('recommends related skills from graph edges', () {
      const service = SkillGraphService(
        edges: [
          SkillGraphEdge(
            fromSkillId: 'python',
            toSkillId: 'data-science',
            relationStrength: 0.9,
          ),
          SkillGraphEdge(
            fromSkillId: 'python',
            toSkillId: 'automation',
            relationStrength: 0.6,
          ),
        ],
      );

      final recommendations = service.recommendRelatedSkills(
        userSkills: const [
          SkillModel(id: 'python', name: 'Python', level: 7),
        ],
      );

      expect(recommendations.first.skillId, 'data-science');
      expect(recommendations.first.score, 0.9);
    });

    test('returns relation strength for related skill matching', () {
      const service = SkillGraphService(
        edges: [
          SkillGraphEdge(
            fromSkillId: 'guitar',
            toSkillId: 'music-theory',
            relationStrength: 0.8,
          ),
        ],
      );

      expect(
        service.relatedSkillScore(
          fromSkillId: 'guitar',
          toSkillId: 'music-theory',
        ),
        0.8,
      );
    });
  });
}
