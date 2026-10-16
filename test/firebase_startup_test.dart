import 'package:coetus/core/firebase/firebase_bootstrap.dart';
import 'package:coetus/core/firebase/firebase_setup_app.dart';
import 'package:coetus/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'unsupported platforms do not silently skip Firebase initialization',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await expectLater(FirebaseBootstrap.initialize(), throwsUnsupportedError);
    },
  );

  testWidgets(
    'missing config shows setup without constructing Firebase-dependent routes',
    (tester) async {
      var builtApplication = false;
      final app = await initializeCoetus(
        initializeFirebase: () async =>
            throw UnsupportedError('Web configuration is missing'),
        buildApplication: () {
          builtApplication = true;
          return const SizedBox();
        },
      );
      expect(builtApplication, isFalse);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.text('Firebase platform ayarı eksik'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('Firebase failures do not construct the application', () async {
    final app = await initializeCoetus(
      initializeFirebase: () async {
        throw FirebaseException(plugin: 'core', code: 'network-request-failed');
      },
      buildApplication: () => throw StateError('Must not build'),
    );
    expect(app, isA<FirebaseSetupApp>());
  });

  test('successful initialization proceeds to the application', () async {
    var initialized = false;
    const expected = SizedBox();
    final app = await initializeCoetus(
      initializeFirebase: () async {
        initialized = true;
      },
      buildApplication: () {
        expect(initialized, isTrue);
        return expected;
      },
    );
    expect(app, same(expected));
  });
}
