import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:coetus/features/matching/models/match_candidate.dart';
import 'package:coetus/features/matching/models/match_explanation.dart';
import 'package:coetus/features/matching/presentation/widgets/match_discovery_widgets.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchCandidate candidate({double compatibility = 1}) => MatchCandidate(
  user: const AppUser(id: 'ada', name: 'Ada', email: '', bio: ''),
  teacherSkill: const SkillModel(id: 'design', name: 'Tasarım', level: 4),
  studentSkill: const SkillModel(id: 'design', name: 'Tasarım', level: 1),
  matchScore: .846,
  skillLevelScore: .6,
  trustScore: .9,
  availabilityScore: 1,
  profileCompleteness: 1,
  fairnessScore: 1,
  creditsRequired: 30,
  explanation: MatchExplanation(
    skillMatchType: SkillMatchType.exact,
    skillCompatibilityScore: compatibility,
    hasAvailabilityOverlap: true,
    averageTrustScore: .9,
    profileCompleteness: 1,
  ),
);

void main() {
  test(
    'compatibility uses rounded score and distinguishes unscored discovery',
    () {
      expect(compatibilityLabel(candidate()), '%85');
      expect(compatibilityLabel(candidate(compatibility: 0)), 'Yeni');
    },
  );

  testWidgets('orbit deduplicates people and opens selected candidate', (
    tester,
  ) async {
    final person = candidate();
    MatchCandidate? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: MatchOrbit(
                candidates: [person, person],
                onSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(MatchAvatar), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(selected, same(person));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rings breathe, avatars are circular and reduced motion stays still',
    (tester) async {
      MatchCandidate? selected;
      Widget orbit({bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: MatchOrbit(
                  candidates: [candidate()],
                  onSelected: (value) => selected = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(orbit());
      final inner = find.byKey(const ValueKey('match-ring-0'));
      final outer = find.byKey(const ValueKey('match-ring-1'));
      final innerBefore = tester.getSize(inner);
      final outerBefore = tester.getSize(outer);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getSize(inner).width, greaterThan(innerBefore.width));
      expect(tester.getSize(outer).width, lessThan(outerBefore.width));
      final avatarMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(MatchAvatar),
          matching: find.byType(Material),
        ),
      );
      expect(avatarMaterial.shape, isA<CircleBorder>());
      expect(avatarMaterial.clipBehavior, Clip.antiAlias);
      await tester.tap(find.byType(MatchAvatar));
      expect(selected?.user.id, 'ada');
      await tester.pumpWidget(orbit(reduced: true));
      final stillSize = tester.getSize(inner);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getSize(inner), stillSize);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('profile card fits a narrow viewport with enlarged text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: MatchProfileCard(candidate: candidate(), onTap: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('%85'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
