import 'package:coetus/features/matching/models/match_candidate.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coetus/app/theme/coetus_theme.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/auth/presentation/pages/login_page.dart';
import 'package:coetus/features/auth/presentation/pages/register_page.dart';
import 'package:coetus/features/matching/presentation/pages/match_success_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/onboarding_intro_page.dart';
import 'package:coetus/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:coetus/features/profile/presentation/pages/other_user_profile_page.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'match_discovery_widgets_test.dart' show candidate;
import 'package:coetus/features/matching/presentation/widgets/match_discovery_widgets.dart';

Widget app(Widget page, {bool reduceMotion = true, double scale = 1}) =>
    MaterialApp(
      theme: coetusTheme(useGoogleFonts: false),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: page,
    );

void main() {
  test('primary text and button pairs meet normal text contrast', () {
    double contrast(Color first, Color second) {
      final a = first.computeLuminance();
      final b = second.computeLuminance();
      return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
    }

    expect(
      contrast(CoetusPalette.purple, CoetusPalette.lime),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(CoetusColors.body, CoetusPalette.cream),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(CoetusColors.muted, CoetusPalette.lavender),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('mascot animates and responds to reduced motion dynamically', (
    tester,
  ) async {
    final celebration = ValueNotifier<int>(0);
    addTearDown(celebration.dispose);
    final mascot = CoetusMascot(celebration: celebration);
    await tester.pumpWidget(app(Scaffold(body: mascot), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 500));
    final transform = find
        .descendant(
          of: find.byType(CoetusMascot),
          matching: find.byType(Transform),
        )
        .first;
    expect(tester.widget<Transform>(transform).transform.storage[13], isNot(0));
    celebration.value++;
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(Scaffold(body: mascot)));
    await tester.pumpAndSettle();
    expect(tester.widget<Transform>(transform).transform.storage[13], 0);
    celebration.value++;
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'welcome celebrates before navigating and ignores repeated starts',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(path: '/welcome', builder: (_, state) => const WelcomePage()),
          GoRoute(
            path: '/onboarding',
            builder: (_, state) =>
                const Scaffold(body: Text('Onboarding destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: coetusTheme(useGoogleFonts: false),
          routerConfig: router,
        ),
      );
      await tester.ensureVisible(find.text('Ücretsiz hesap aç'));
      await tester.tap(find.text('Ücretsiz hesap aç'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Onboarding destination'), findsNothing);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Onboarding destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  final pages = <String, Widget>{
    'welcome': const WelcomePage(),
    'onboarding': const OnboardingIntroPage(),
    'login': const LoginPage(),
    'register': const RegisterPage(),
    'success': const MatchSuccessPage(
      user: MatchedUser(
        name: 'Deniz',
        skills: [MatchedSkill(name: 'Tasarım', emoji: '🎨')],
        learningGoals: [MatchedGoal(name: 'Yazılım', emoji: '💻')],
      ),
    ),
    'profile': const OtherUserProfilePage(
      profile: OtherUserProfileData(
        id: 'deniz',
        name: 'Deniz',
        location: 'İstanbul',
        bio: 'Birlikte üretiyoruz.',
        trustScore: 94,
        verified: true,
        matchScore: 85,
        creditsRequired: 30,
      ),
    ),
    'discovery': Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            MatchOrbit(
              candidates: List.generate(6, (i) {
                final c = candidate();
                return previewCandidate(c, i);
              }),
              onSelected: (_) {},
            ),
            const SizedBox(height: 16),
            MatchProfileCard(candidate: candidate(), onTap: () {}),
          ],
        ),
      ),
    ),
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key} fits narrow screens and enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(entry.value, scale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('render design previews when requested', (tester) async {
    final directory = Platform.environment['COETUS_PREVIEW_DIR'];
    if (directory == null) return;
    // Load a local UI font solely for readable development screenshots.
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      if (await font.exists()) {
        final loader = FontLoader('PreviewUI')
          ..addFont(font.readAsBytes().then((b) => ByteData.sublistView(b)));
        await loader.load();
      }
      final icons = File(
        'C:/src/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      );
      if (await icons.exists()) {
        final loader = FontLoader('MaterialIcons')
          ..addFont(icons.readAsBytes().then((b) => ByteData.sublistView(b)));
        await loader.load();
      }
    });
    tester.view.physicalSize = const Size(390, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in pages.entries) {
      final key = GlobalKey();
      final theme = coetusTheme(
        useGoogleFonts: false,
        fallbackFontFamily: 'PreviewUI',
      );
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(entry.key),
          theme: theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: 'PreviewUI'),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: RepaintBoundary(key: key, child: child!),
          ),
          home: entry.value,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await Directory(directory).create(recursive: true);
        await File(
          '$directory/${entry.key}.png',
        ).writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}

MatchCandidate previewCandidate(MatchCandidate c, int index) => MatchCandidate(
  user: c.user.copyWith(
    id: 'person-$index',
    name: ['Ada', 'Deniz', 'Ece', 'Can', 'İpek', 'Mert'][index],
  ),
  teacherSkill: c.teacherSkill,
  studentSkill: c.studentSkill,
  matchScore: c.matchScore - index * .03,
  skillLevelScore: c.skillLevelScore,
  trustScore: c.trustScore,
  availabilityScore: c.availabilityScore,
  profileCompleteness: c.profileCompleteness,
  fairnessScore: c.fairnessScore,
  creditsRequired: c.creditsRequired,
  explanation: c.explanation,
);
