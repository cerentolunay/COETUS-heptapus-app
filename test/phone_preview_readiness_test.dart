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
      expect(Firebase.apps, isEmpty);
      await tester.tap(find.text('Ekranlar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ekranları incele'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
