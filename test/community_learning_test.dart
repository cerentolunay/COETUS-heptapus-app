import 'package:coetus/features/matching/presentation/pages/skill_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'design_refresh_test.dart' show app;
import 'match_discovery_widgets_test.dart' show candidate;

void main() {
  testWidgets(
    'learning offer explains token lock and cancellation sends nothing',
    (tester) async {
      var sent = 0;
      await tester.pumpWidget(
        app(
          SkillDetailPage(
            candidate: candidate(),
            onSendOffer: () => sent++,
            onViewProfile: () {},
          ),
        ),
      );
      await tester.tap(find.text('Ücretsiz teklif gönder'));
      await tester.pumpAndSettle();
      expect(sent, 0);
      expect(
        find.textContaining('Sonraki adımda karşılıklı becerileri'),
        findsOneWidget,
      );
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(sent, 0);
      expect(find.byType(SkillDetailPage), findsOneWidget);
    },
  );
  testWidgets('only explicit confirmation sends the learning offer', (
    tester,
  ) async {
    var sent = 0;
    await tester.pumpWidget(
      app(
        SkillDetailPage(
          candidate: candidate(),
          onSendOffer: () => sent++,
          onViewProfile: () {},
        ),
      ),
    );
    await tester.tap(find.text('Ücretsiz teklif gönder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teklif gönder'));
    await tester.pumpAndSettle();
    expect(sent, 1);
  });
  testWidgets('learning offer fits narrow screens and enlarged Turkish text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        SkillDetailPage(
          candidate: candidate(),
          onSendOffer: () {},
          onViewProfile: () {},
        ),
        scale: 1.4,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ücretsiz teklif gönder'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Birlikte öğrenme teklifi'), findsOneWidget);
  });
}
