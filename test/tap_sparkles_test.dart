import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/widgets/coetus_tap_sparkles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty-space taps create red hearts and sparkles then clean up', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CoetusTapSparkles(child: SizedBox.expand())),
      ),
    );
    await tester.tapAt(const Offset(60, 100));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.auto_awesome), findsNWidgets(6));
    for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
      expect(icon.color, CoetusPalette.red);
    }
    await tester.tapAt(const Offset(160, 200));
    await tester.pump();
    expect(find.byType(Icon), findsNWidgets(20));
    await tester.pumpAndSettle();
    expect(find.byType(Icon), findsNothing);
  });
  testWidgets(
    'child taps keep their own action and rapid bursts stay bounded',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoetusTapSparkles(
              child: Center(
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const SizedBox(
                    width: 100,
                    height: 100,
                    child: ColoredBox(color: Colors.blue),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ColoredBox).last);
      await tester.pump();
      expect(taps, 1);
      expect(find.byType(Icon), findsNothing);
      for (var i = 0; i < 20; i++) {
        await tester.tapAt(const Offset(20, 40));
        await tester.pump();
      }
      expect(find.byType(Icon), findsNWidgets(120));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('reduced motion does not create particle animations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: CoetusTapSparkles(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.tapAt(const Offset(60, 100));
    await tester.pumpAndSettle();
    expect(find.byType(Icon), findsNothing);
  });
}
