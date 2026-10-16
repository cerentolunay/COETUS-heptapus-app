import 'dart:io';
import 'dart:ui' as ui;
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('export Coetus mascot launcher source', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: CoetusPalette.purple,
            body: Center(
              child: CoetusMascot(
                size: 880,
                animate: false,
                interactive: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await File(
        'assets/icons/app_icon.png',
      ).writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
  });
}
