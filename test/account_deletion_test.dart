import 'dart:async';
import 'package:coetus/features/auth/data/services/account_deletion_service.dart';
import 'package:coetus/features/auth/presentation/widgets/delete_account_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'design_refresh_test.dart' show app;

Future<void> openDeletion(
  WidgetTester tester,
  Future<AccountDeletionResult> Function(String) onDelete, {
  bool password = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    app(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<AccountDeletionResult>(
              context: context,
              barrierDismissible: false,
              builder: (_) => DeleteAccountDialog(
                onDelete: onDelete,
                requiresPassword: password,
              ),
            ),
            child: const Text('Aç'),
          ),
        ),
      ),
      scale: scale,
    ),
  );
  await tester.tap(find.text('Aç'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'deletion requires acknowledgement and cancellation changes nothing',
    (tester) async {
      var calls = 0;
      await openDeletion(tester, (_) async {
        calls++;
        return const AccountDeletionResult();
      });
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byType(DeleteAccountDialog), findsNothing);
    },
  );
  testWidgets('password is required and obscured before deletion', (
    tester,
  ) async {
    var calls = 0;
    await openDeletion(tester, (_) async {
      calls++;
      return const AccountDeletionResult();
    }, password: true);
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Evet, hesabımı sil'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Devam etmek için şifreni yaz.'), findsOneWidget);
  });
  testWidgets('deletion waits for success and ignores duplicate taps', (
    tester,
  ) async {
    final pending = Completer<AccountDeletionResult>();
    var calls = 0;
    await openDeletion(tester, (_) async {
      calls++;
      return pending.future;
    });
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Evet, hesabımı sil'));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Hesabın siliniyor…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Vazgeç'))
          .onPressed,
      isNull,
    );
    pending.complete(const AccountDeletionResult());
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });
  testWidgets('failed deletion stays open and allows retry', (tester) async {
    var calls = 0;
    await openDeletion(tester, (_) async {
      calls++;
      if (calls == 1) throw StateError('Kilitli oturumunu önce tamamla.');
      return const AccountDeletionResult();
    });
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Evet, hesabımı sil'));
    await tester.pumpAndSettle();
    expect(find.text('Kilitli oturumunu önce tamamla.'), findsOneWidget);
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    await tester.tap(find.text('Evet, hesabımı sil'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });
  testWidgets(
    'delete confirmation fits narrow screens and enlarged Turkish text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openDeletion(
        tester,
        (_) async => const AccountDeletionResult(),
        password: true,
        scale: 1.4,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Hesabını kalıcı olarak sil?'), findsOneWidget);
    },
  );
}
