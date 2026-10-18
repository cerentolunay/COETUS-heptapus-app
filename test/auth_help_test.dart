import 'dart:async';
import 'package:coetus/features/auth/data/services/google_sign_in_error.dart';
import 'package:coetus/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Google errors distinguish provider, Android signature and profile permissions',
    () {
      expect(
        googleSignInError(FirebaseAuthException(code: 'operation-not-allowed')),
        contains('etkin değil'),
      );
      expect(
        googleSignInError(
          PlatformException(
            code: 'sign_in_failed',
            message: 'ApiException: 10:',
          ),
        ),
        contains('SHA'),
      );
      expect(
        googleSignInError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        contains('güvenlik kuralları'),
      );
    },
  );
  testWidgets(
    'reset validates email, waits for sending and prevents duplicate requests',
    (tester) async {
      final pending = Completer<void>();
      final emails = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordPage(
            sendResetEmail: (email) {
              emails.add(email);
              return pending.future;
            },
          ),
        ),
      );
      await tester.tap(find.text('Sıfırlama bağlantısı gönder'));
      await tester.pump();
      expect(find.text('Geçerli bir e-posta adresi gir.'), findsOneWidget);
      expect(emails, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        '  deniz@example.test  ',
      );
      await tester.tap(find.text('Sıfırlama bağlantısı gönder'));
      await tester.pump();
      expect(emails, ['deniz@example.test']);
      expect(find.text('E-postanı kontrol et'), findsNothing);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('E-postanı kontrol et'), findsOneWidget);
    },
  );
  testWidgets('failed reset stays on form and permits retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          sendResetEmail: (email) async {
            attempts++;
            throw FirebaseAuthException(code: 'network-request-failed');
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'deniz@example.test');
    await tester.tap(find.text('Sıfırlama bağlantısı gönder'));
    await tester.pumpAndSettle();
    expect(find.text('E-postanı kontrol et'), findsNothing);
    expect(
      find.text('Bağlantı kurulamadı. İnternet bağlantını kontrol et.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Sıfırlama bağlantısı gönder'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });
}
