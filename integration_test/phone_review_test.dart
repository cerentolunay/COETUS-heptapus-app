import 'package:coetus/features/auth/data/repositories/local_auth_repository.dart';
import 'package:coetus/preview/preview_app.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceReady = false;
  setUp(() async {
    PreviewMode.enable();
    await LocalAuthRepository().signUp(
      fullName: 'Deniz',
      email: 'deniz@example.invalid',
      password: 'preview-only',
    );
  });
  for (final entry in previewScreens.indexed) {
    final screen = entry.$2;
    testWidgets('physical phone: ${screen.name}', (tester) async {
      await tester.pumpWidget(
        PreviewApp(key: ValueKey(screen.path), initialLocation: screen.path),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(Firebase.apps, isEmpty);
      expect(find.text('ÖNİZLEME · ÇEVRİMDIŞI'), findsOneWidget);
      if (!surfaceReady) {
        await binding.convertFlutterSurfaceToImage();
        surfaceReady = true;
        await tester.pump();
      }
      await binding.takeScreenshot(
        'screen-${(entry.$1 + 1).toString().padLeft(2, '0')}',
      );
      await tester.tap(find.text('Ekranlar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Ekranları incele'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
