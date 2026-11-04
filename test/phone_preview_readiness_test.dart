import 'package:coetus/features/auth/data/repositories/local_auth_repository.dart';
import 'package:coetus/preview/preview_app.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    PreviewMode.enable();
    await LocalAuthRepository().signUp(
      fullName: 'Deniz',
      email: 'deniz@example.invalid',
      password: 'preview-only',
    );
  });
  for (final screen in previewScreens) {
    testWidgets('phone 320x640 large text: ${screen.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(PreviewApp(initialLocation: screen.path));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(Firebase.apps, isEmpty);
      await tester.tap(find.text('Ekranlar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ekranları incele'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final screen in previewScreens.where(
    (s) => [
      '/login',
      '/register',
      '/profile/edit',
      '/chat-detail/preview-chat',
    ].contains(s.path),
  )) {
    testWidgets('simulated keyboard and back: ${screen.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const PreviewApp());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.byType(TextField),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), screen.name);
      await tester.pump();
      tester.testTextInput.hide();
      final tile = find.widgetWithText(ListTile, screen.name);
      await tester.scrollUntilVisible(
        tile,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tile);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final input = find.byType(EditableText).last;
      await tester.ensureVisible(input);
      await tester.showKeyboard(input);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(input);
      expect(tester.takeException(), isNull);
      expect(find.text('ÖNİZLEME · ÇEVRİMDIŞI'), findsOneWidget);
      expect(Firebase.apps, isEmpty);
      tester.testTextInput.hide();
      tester.view.resetViewInsets();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.widgetWithText(ListTile, screen.name), findsOneWidget);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      expect(find.text('Ekranları incele'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('preview explains that token balances are examples', (
    tester,
  ) async {
    await tester.pumpWidget(const PreviewApp());
    expect(find.textContaining('gerçek bakiyen değildir'), findsOneWidget);
    expect(Firebase.apps, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
