import 'package:coetus/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login form', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Tekrar hoş geldin'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);
  });
}
