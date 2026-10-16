import 'dart:async';
import 'package:coetus/app/theme/coetus_theme.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/profile/domain/models/skill_model.dart';
import 'package:coetus/features/verification/domain/skill_verification.dart';
import 'package:coetus/features/verification/presentation/verification_page.dart';
import 'package:coetus/features/matching/presentation/widgets/match_discovery_widgets.dart';
import 'package:coetus/widgets/coetus_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'match_discovery_widgets_test.dart' show candidate;
import 'design_refresh_test.dart' show previewCandidate;

void main() {
  test('verification is tied to the approved skill name and level', () {
    final skill = SkillModel.fromMap({
      'id': 'guitar',
      'name': 'Gitar',
      'level': 5,
      'verifiedName': 'Gitar',
      'verifiedLevel': 5,
    });
    expect(skill.verified, isTrue);
    expect(skill.copyWith(name: 'Piyano').verified, isFalse);
    expect(skill.copyWith(level: 7).verified, isFalse);
    expect(skill.toMap().containsKey('verifiedName'), isFalse);
    expect(skill.toMap().containsKey('verifiedLevel'), isFalse);
  });
  test(
    'top match depends on the actual score and ignores unscored discovery',
    () {
      final people = [
        previewCandidate(candidate(), 3),
        previewCandidate(candidate(), 0),
      ];
      expect(bestMatchUserId(people), 'person-0');
      expect(bestMatchUserId(people.reversed.toList()), 'person-0');
      expect(bestMatchUserId([candidate(compatibility: 0)]), isNull);
    },
  );
  test('red accent has readable dark foreground', () {
    final ratio =
        (CoetusPalette.red.computeLuminance() + .05) /
        (CoetusPalette.onRed.computeLuminance() + .05);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });
  testWidgets('delete waits for success and cannot be double submitted', (
    tester,
  ) async {
    final completer = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: coetusTheme(useGoogleFonts: false),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => CoetusDeleteDialog(
                  name: 'Gitar',
                  onDelete: () {
                    calls++;
                    return completer.future;
                  },
                ),
              ),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evet, sil'));
    await tester.pump();
    expect(find.text('Siliniyor…'), findsOneWidget);
    expect(calls, 1);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CoetusDeleteDialog), findsNothing);
  });
  testWidgets('failed deletion remains visible and offers retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: coetusTheme(useGoogleFonts: false),
        home: Scaffold(
          body: CoetusDeleteDialog(
            name: 'Yazılım',
            onDelete: () async => throw StateError('network'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Evet, sil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Silinemedi. Bağlantını kontrol edip yeniden dene.'),
      findsOneWidget,
    );
    expect(find.text('Evet, sil'), findsOneWidget);
  });
  testWidgets(
    'portfolio is distinguished from peer endorsement and never claims identity',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const VerificationCard(
                  verification: SkillVerification(
                    id: 'pending',
                    ownerId: 'owner',
                    skillName: 'Gitar',
                    status: 'published',
                    type: 'portfolio',
                    description: 'Gitar çalıyorum.',
                  ),
                ),
                const VerificationCard(
                  verification: SkillVerification(
                    id: 'approved',
                    ownerId: 'owner',
                    skillName: 'Yazılım',
                    status: 'approved',
                    type: 'peer',
                    description: 'Yazılım öğrendim.',
                    studentName: 'Ece',
                    reward: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.textContaining('Çalışma örneği paylaşıldı'), findsOneWidget);
      expect(find.textContaining('+10 token'), findsOneWidget);
      expect(find.textContaining('Ece tarafından onaylandı'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
