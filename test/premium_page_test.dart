import 'package:coetus/preview/preview_app.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/features/premium/presentation/pages/premium_page.dart';
import 'package:coetus/widgets/coetus_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final path in ['/profile', '/matching']) {
    testWidgets('$path token opens Premium in the app', (tester) async {
      PreviewMode.enable();
      await tester.pumpWidget(PreviewApp(initialLocation: path));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final entry = path == '/profile'
          ? find.text('TOKEN')
          : find.byType(CreditBadge).first;
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Premium ve token'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('token badge opens packages and back restores the source', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Center(child: CreditBadge(amount: 80))),
        ),
        GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('80 token'));
    await tester.pumpAndSettle();
    expect(find.text('Premium ve token'), findsOneWidget);
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('80 token'), findsOneWidget);
  });
  testWidgets(
    'packages fit a small screen with enlarged text and cannot charge',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const PremiumPage(),
          ),
        ),
      );
      expect(find.text('Sınırsız eşleşme'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('250 token'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('250 token'), findsOneWidget);
      expect(find.byType(FilledButton), findsNWidgets(2));
      for (final button in tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      )) {
        expect(button.onPressed, isNull);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
