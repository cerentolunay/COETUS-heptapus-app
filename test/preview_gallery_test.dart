import 'package:coetus/preview/preview_app.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/features/auth/data/repositories/local_auth_repository.dart';
import 'package:coetus/features/community/community.dart';
import 'package:coetus/features/auth/presentation/widgets/delete_account_button.dart';
import 'package:coetus/features/verification/data/verification_service.dart';
import 'package:coetus/features/profile/data/repositories/profile_repository_factory.dart';
import 'package:coetus/features/profile/data/repositories/firebase_profile_repository.dart';
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
    testWidgets('${screen.name} renders offline and returns to gallery', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(PreviewApp(initialLocation: screen.path));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(Firebase.apps, isEmpty);
      expect(find.text('ÖNİZLEME · ÇEVRİMDIŞI'), findsOneWidget);
      await tester.tap(find.text('Ekranlar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ekranları incele'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('gallery search opens screen without signing in', (tester) async {
    await tester.pumpWidget(const PreviewApp());
    await tester.enterText(find.byType(TextField), 'Bildirim');
    await tester.pump();
    await tester.tap(find.text('Bildirimler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ece sana mesaj gönderdi'), findsOneWidget);
    expect(Firebase.apps, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'preview blocks server mutations and uses an offline repository',
    () async {
      expect(
        ProfileRepositoryFactory.create(),
        isNot(isA<FirebaseProfileRepository>()),
      );
      await expectLater(
        communityCall('supportCommunityPost', {'amount': 3}),
        throwsStateError,
      );
      await expectLater(
        VerificationService().submit(
          skillId: 'gitar',
          description: 'Örnek çalışma açıklaması',
          files: [],
          onProgress: (_) {},
        ),
        throwsStateError,
      );
      expect(Firebase.apps, isEmpty);
    },
  );

  testWidgets('sample comments stay local', (tester) async {
    await tester.pumpWidget(const PreviewApp(initialLocation: '/comments'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Birlikte çalışalım!');
    await tester.tap(find.text('Yorumu gönder'));
    await tester.pump();
    expect(find.text('Birlikte çalışalım!'), findsOneWidget);
    expect(Firebase.apps, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sample chat sends messages only to memory', (tester) async {
    await tester.pumpWidget(
      const PreviewApp(initialLocation: '/chat-detail/preview-chat'),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.enterText(find.byType(TextField), 'Örnek mesajım');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Örnek mesajım'), findsOneWidget);
    expect(Firebase.apps, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('account deletion confirmation cannot delete a real account', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PreviewApp(initialLocation: '/delete-account'),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final dialog = find.byType(DeleteAccountDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'preview-only',
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final confirm = find.descendant(
      of: dialog,
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
    expect(find.text('Önizleme: gerçek hesap silinmez.'), findsOneWidget);
    expect(Firebase.apps, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
