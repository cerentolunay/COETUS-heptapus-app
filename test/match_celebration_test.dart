import 'package:coetus/features/matching/presentation/pages/match_success_page.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('heart animates and respects reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 104, height: 112, child: MatchHeartSparkles()),
        ),
      ),
    );
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SizedBox(width: 104, height: 112, child: MatchHeartSparkles()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
  testWidgets(
    'new-account preview celebrates without an additional match gift',
    (tester) async {
      PreviewMode.enable();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MatchSuccessPage(
            user: MatchedUser(name: 'Ece', skills: [], learningGoals: []),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('first-match-gift')), findsNothing);
      expect(find.text('COETUS’tan sana hediye 20 token!'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
