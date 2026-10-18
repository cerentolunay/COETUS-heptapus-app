import 'package:coetus/features/profile/presentation/widgets/interest_catalog_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('suggestion validates input without publishing preview data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterestCatalogPanel(builder: (_) => const SizedBox()),
        ),
      ),
    );
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Öneriyi gönder'));
    await tester.pumpAndSettle();
    expect(find.text('En az 2 karakter yaz.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Astronomi');
    await tester.tap(find.text('Öneriyi gönder'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Önizlemede öneri gönderilmez. Gerçek hesabınla giriş yapmalısın.',
      ),
      findsOneWidget,
    );
    expect(find.text('Önerileri incele'), findsNothing);
  });
  testWidgets('existing interest cannot be suggested again', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterestCatalogPanel(builder: (_) => const SizedBox()),
        ),
      ),
    );
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'PSİKOLOJİ');
    await tester.tap(find.text('Öneriyi gönder'));
    await tester.pumpAndSettle();
    expect(find.text('Bu ilgi alanı zaten listede.'), findsOneWidget);
  });
}
