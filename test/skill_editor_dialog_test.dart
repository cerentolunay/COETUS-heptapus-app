import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/profile/domain/onboarding/interest_catalog.dart';
import 'package:coetus/features/profile/presentation/widgets/interest_tree.dart';
import 'package:coetus/features/profile/presentation/widgets/skill_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'sharing saves level only after confirmation and cancel preserves choices',
    (tester) async {
      final selection = InterestSelection()
        ..toggleSkill('Gitar', 'Müzik', branchId: 'music');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, update) => InterestTree(
                  selection: selection,
                  onChanged: () => update(() {}),
                ),
              ),
            ),
          ),
        ),
      );
      final share = find.text('Bu beceriyi paylaşabilirim');
      await tester.ensureVisible(share);
      await tester.tap(share);
      await tester.pumpAndSettle();
      expect(find.byType(SkillEditorDialog), findsOneWidget);
      expect(selection.skills.values.single.teach, isFalse);
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).backgroundColor,
        CoetusPalette.purple,
      );
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(selection.skills.values.single.teach, isFalse);
      await tester.tap(share);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Slider), const Offset(80, 0));
      await tester.pumpAndSettle();
      final chosen = tester.widget<Slider>(find.byType(Slider)).value.round();
      expect(chosen, greaterThan(1));
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      expect(selection.skills.values.single.teach, isTrue);
      expect(selection.skills.values.single.level, chosen);
      expect(selection.skills.values.single.learn, isTrue);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    },
  );
  testWidgets('editor validates names and fits narrow enlarged screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: const Scaffold(body: SkillEditorDialog()),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Beceri adını yaz.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
