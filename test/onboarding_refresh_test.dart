import 'package:coetus/features/onboarding/presentation/pages/discovery_test_page.dart';
import 'package:coetus/features/profile/presentation/widgets/interest_tree.dart';
import 'package:coetus/core/text/skill_normalization.dart';
import 'package:coetus/features/auth/domain/models/app_user.dart';
import 'package:coetus/features/matching/services/matching_service.dart';
import 'package:coetus/features/profile/domain/models/profile_data.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import 'package:coetus/features/profile/domain/onboarding/interest_catalog.dart';
import 'package:coetus/features/profile/domain/onboarding/profile_setup_data.dart';
import 'package:coetus/features/profile/domain/services/profile_location_service.dart';
import 'package:coetus/features/profile/presentation/pages/complete_profile_page.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'design_refresh_test.dart' show app;

void main() {
  testWidgets('entry and profile completion share the same expandable cards', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DiscoveryTestPage()));
    await tester.pumpAndSettle();
    expect(find.byType(InterestTree), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Gitar'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('interest-branch-music')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Gitar'), findsOneWidget);
    await tester.pumpWidget(
      app(
        CompleteProfilePage(
          initialName: 'Deniz',
          onSubmit: (_) async {},
          onCompleted: () {},
        ),
      ),
    );
    await tester.ensureVisible(find.text('İlgi alanlarına devam et'));
    await tester.tap(find.text('İlgi alanlarına devam et'));
    await tester.pumpAndSettle();
    expect(find.byType(InterestTree), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('interest-branch-music')),
    );
    await tester.tap(find.byKey(const ValueKey('interest-branch-music')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Gitar'), findsOneWidget);
  });

  testWidgets('entry selections carry into final profile submission', (
    tester,
  ) async {
    final draft = InterestSelection()
      ..toggleBranch('music')
      ..toggleSkill('Gitar', 'Müzik', branchId: 'music');
    draft.skills.values.single.teach = true;
    draft.skills.values.single.level = 4;
    ProfileSetupData? saved;
    await tester.pumpWidget(
      app(
        CompleteProfilePage(
          initialName: 'Deniz',
          initialSelection: draft,
          onSubmit: (data) async => saved = data,
          onCompleted: () {},
        ),
      ),
    );
    await tester.ensureVisible(find.text('İlgi alanlarına devam et'));
    await tester.tap(find.text('İlgi alanlarına devam et'));
    await tester.pumpAndSettle();
    final guitar = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Gitar'),
    );
    expect(guitar.selected, isTrue);
    await tester.ensureVisible(find.text('Profilimi tamamla'));
    await tester.tap(find.text('Profilimi tamamla'));
    await tester.pumpAndSettle();
    expect(saved!.interests, contains('music'));
    expect(saved!.skills.single.name, 'Gitar');
    expect(saved!.skills.single.teachable, isTrue);
    expect(saved!.skills.single.learnable, isTrue);
    expect(saved!.skills.single.level, 4);
  });

  test(
    'normalization handles Turkish, case, spacing and decomposed letters without merging languages',
    () {
      for (final text in [' YAZILIM ', 'Yazılım', 'yazilim', 'YAZİLİM']) {
        expect(skillKey(text), 'yazilim');
      }
      expect(skillKey('I\u0307ngilizce'), skillKey('İNGİLİZCE'));
      expect(skillKey('ŞAN'), skillKey('s\u0327an'));
      expect(skillKey('C++'), isNot(skillKey('C#')));
      expect(skillKey('Java'), isNot(skillKey('JavaScript')));
    },
  );
  test(
    'real matching returns the same exact result for Python and Turkish variants',
    () {
      for (final names in [
        ['python', 'Python'],
        ['PYTHON', 'python'],
        ['YAZİLİM', 'yazılım'],
        ['muzik', 'MÜZİK'],
        ['Guitar', 'gitar'],
      ]) {
        final current = ProfileData(
          user: const AppUser(id: 'learner', name: 'Deniz', email: '', bio: ''),
          teachSkills: const [],
          learnSkills: [SkillModel(id: 'a', name: names[0], level: 1)],
        );
        final teacher = ProfileData(
          user: const AppUser(id: 'partner', name: 'Ece', email: '', bio: ''),
          teachSkills: [SkillModel(id: 'b', name: names[1], level: 5)],
          learnSkills: const [],
        );
        final result = const MatchingService().getRecommendedMatches(
          currentProfile: current,
          candidateProfiles: [teacher],
        );
        expect(result, hasLength(1), reason: names.join('/'));
        expect(result.single.explanation.skillCompatibilityScore, 1);
      }
    },
  );
  test(
    'collapsing a branch preserves selections and their parent interests',
    () {
      final selection = InterestSelection()
        ..toggleBranch('music')
        ..toggleSkill('Gitar', 'Müzik')
        ..toggleBranch('music');
      expect(selection.branches, isEmpty);
      expect(selection.selectedInterestIds, contains('music'));
      selection.toggleSkill('guitar', 'Müzik');
      expect(selection.selectedSkills, isEmpty);
    },
  );
  test(
    'location denied never reads position and leaves manual entry available',
    () async {
      var requested = 0, resolved = 0;
      final service = ProfileLocationService(
        enabled: () async => true,
        check: () async => LocationPermission.denied,
        request: () async {
          requested++;
          return LocationPermission.denied;
        },
        resolve: () async {
          resolved++;
          return 'İstanbul, Türkiye';
        },
      );
      await expectLater(service.locateCity(), throwsA(isA<LocationFailure>()));
      expect(requested, 1);
      expect(resolved, 0);
    },
  );
  test(
    'permanently denied location requests no new permission dialog',
    () async {
      var requested = 0;
      final service = ProfileLocationService(
        enabled: () async => true,
        check: () async => LocationPermission.deniedForever,
        request: () async {
          requested++;
          return LocationPermission.whileInUse;
        },
        resolve: () async => 'İstanbul, Türkiye',
      );
      await expectLater(
        service.locateCity(),
        throwsA(
          isA<LocationFailure>().having((e) => e.settings, 'settings', true),
        ),
      );
      expect(requested, 0);
    },
  );
  test('location service off never requests permission', () async {
    var requested = 0;
    final service = ProfileLocationService(
      enabled: () async => false,
      check: () async {
        requested++;
        return LocationPermission.denied;
      },
      resolve: () async => 'İstanbul, Türkiye',
    );
    await expectLater(service.locateCity(), throwsA(isA<LocationFailure>()));
    expect(requested, 0);
  });
  test('allowed location returns only city label', () async {
    final service = ProfileLocationService(
      enabled: () async => true,
      check: () async => LocationPermission.whileInUse,
      resolve: () async => 'İstanbul, Türkiye',
    );
    expect(await service.locateCity(), 'İstanbul, Türkiye');
  });
  testWidgets(
    'onboarding saves only on final step and accepts no optional skills',
    (tester) async {
      ProfileSetupData? saved;
      var completed = false;
      await tester.pumpWidget(
        app(
          CompleteProfilePage(
            initialName: 'Deniz',
            onSubmit: (data) async => saved = data,
            onCompleted: () => completed = true,
          ),
        ),
      );
      expect(find.byType(CoetusMascot), findsOneWidget);
      expect(find.textContaining('Alex Chen'), findsNothing);
      expect(find.text('Daha sonra atla'), findsNothing);
      final next = find.text('İlgi alanlarına devam et');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(find.text('İlgi alanlarını keşfet'), findsOneWidget);
      final finish = find.text('Profilimi tamamla');
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(saved!.displayName, 'Deniz');
      expect(saved!.bio, isEmpty);
      expect(saved!.skills, isEmpty);
      expect(completed, isTrue);
    },
  );
  testWidgets('expanded categories save chosen skills with explicit intent', (
    tester,
  ) async {
    ProfileSetupData? saved;
    await tester.pumpWidget(
      app(
        CompleteProfilePage(
          initialName: 'Deniz',
          onSubmit: (data) async => saved = data,
          onCompleted: () {},
        ),
      ),
    );
    await tester.ensureVisible(find.text('İlgi alanlarına devam et'));
    await tester.tap(find.text('İlgi alanlarına devam et'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('interest-branch-music')),
    );
    await tester.tap(find.byKey(const ValueKey('interest-branch-music')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Gitar'));
    await tester.tap(find.widgetWithText(FilterChip, 'Gitar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bu beceriyi paylaşabilirim'));
    await tester.tap(find.text('Bu beceriyi paylaşabilirim'));
    await tester.pumpAndSettle();
    expect(find.text('Becerini paylaş'), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Profilimi tamamla'));
    await tester.tap(find.text('Profilimi tamamla'));
    await tester.pumpAndSettle();
    expect(saved!.interests, contains('music'));
    expect(saved!.skills.single.name, 'Gitar');
    expect(saved!.skills.single.learnable, isTrue);
    expect(saved!.skills.single.teachable, isTrue);
  });
  testWidgets(
    'location is requested only on tap and denial does not block onboarding',
    (tester) async {
      var requests = 0;
      await tester.pumpWidget(
        app(
          CompleteProfilePage(
            initialName: 'Deniz',
            onSubmit: (_) async {},
            onCompleted: () {},
            locateCity: () async {
              requests++;
              throw const LocationFailure(
                'İzin verilmedi; şehrini elle yazabilirsin.',
              );
            },
          ),
        ),
      );
      expect(requests, 0);
      await tester.ensureVisible(find.text('Konumumdan şehri bul'));
      await tester.tap(find.text('Konumumdan şehri bul'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(
        find.text('İzin verilmedi; şehrini elle yazabilirsin.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('İlgi alanlarına devam et'));
      await tester.tap(find.text('İlgi alanlarına devam et'));
      await tester.pumpAndSettle();
      expect(find.text('İlgi alanlarını keşfet'), findsOneWidget);
    },
  );
  testWidgets(
    'profile form and expanded interests fit narrow enlarged screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          CompleteProfilePage(
            initialName: 'Deniz',
            onSubmit: (_) async {},
            onCompleted: () {},
          ),
          scale: 1.4,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('İlgi alanlarına devam et'));
      await tester.tap(find.text('İlgi alanlarına devam et'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('interest-branch-music')),
      );
      await tester.tap(find.byKey(const ValueKey('interest-branch-music')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
