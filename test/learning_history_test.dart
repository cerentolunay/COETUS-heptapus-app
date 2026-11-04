import 'dart:async';
import 'package:coetus/app/theme/coetus_theme.dart';
import 'package:coetus/features/exchange/data/repositories/local_exchange_repository.dart';
import 'package:coetus/features/exchange/domain/models/exchange_session.dart';
import 'package:coetus/features/profile/domain/learning_history.dart';
import 'package:coetus/features/profile/presentation/widgets/learning_history_stats.dart';
import 'package:coetus/features/exchange/presentation/pages/exchange_page.dart';
import 'package:coetus/preview/preview_app.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ExchangeSession session(
  String id, {
  bool taught = true,
  int? day,
  int? createdDay,
  ExchangeSessionStatus status = ExchangeSessionStatus.completed,
  bool participant = true,
}) => ExchangeSession(
  id: id,
  matchId: id,
  teacherId: taught ? 'me' : 'partner',
  studentId: taught ? 'partner' : 'me',
  participants: participant ? const ['me', 'partner'] : const ['other'],
  skill: id,
  credits: 10,
  status: status,
  updatedAt: day == null ? null : DateTime(2026, 10, day, 14),
  createdAt: createdDay == null ? null : DateTime(2026, 10, createdDay),
);

class HistoryRepository extends LocalExchangeRepository {
  final controller = StreamController<List<ExchangeSession>>.broadcast();
  int calls = 0;
  @override
  Stream<List<ExchangeSession>> streamUserSessions(String userId) {
    calls++;
    return controller.stream;
  }
}

Widget app(HistoryRepository repo, {ValueChanged<String>? onOpen}) =>
    MaterialApp(
      theme: coetusTheme(useGoogleFonts: false),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: LearningHistoryStats(
              userId: 'me',
              repository: repo,
              onOpenSession: onOpen ?? (_) {},
            ),
          ),
        ),
      ),
    );

void main() {
  test(
    'history excludes noncompleted, other role and unrelated sessions; newest first',
    () {
      final sessions = [
        session('undated'),
        session('old', day: 2, createdDay: 1),
        session('created-only', createdDay: 8),
        session('new', day: 19, createdDay: 1),
        session('learned', taught: false, day: 19),
        session('active', day: 19, status: ExchangeSessionStatus.active),
        session('cancelled', day: 19, status: ExchangeSessionStatus.cancelled),
        session('unrelated', day: 19, participant: false),
      ];
      expect(
        completedLearningHistory(
          sessions,
          'me',
          LearningHistoryRole.taught,
        ).map((s) => s.id),
        ['new', 'created-only', 'old', 'undated'],
      );
      expect(
        completedLearningHistory(
          sessions,
          'me',
          LearningHistoryRole.learned,
        ).map((s) => s.id),
        ['learned'],
      );
      expect(
        completedLearningHistory(sessions, '', LearningHistoryRole.taught),
        isEmpty,
      );
      expect(
        sessions.first.id,
        'undated',
      ); // Sorting doesn't mutate repository data.
    },
  );

  testWidgets(
    'both counters open matching histories using one live subscription',
    (tester) async {
      final repo = HistoryRepository();
      addTearDown(repo.controller.close);
      String? opened;
      await tester.pumpWidget(app(repo, onOpen: (id) => opened = id));
      repo.controller.add([
        session('Eski Gitar', day: 1),
        session('Yeni Piyano', day: 19),
        session('Enstrüman', createdDay: 4),
        session('Python', taught: false, day: 18),
        session('Tasarım', taught: false, day: 17),
      ]);
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('ÖĞRETTİM'));
      await tester.pumpAndSettle();
      expect(find.text('Öğrettiklerim'), findsOneWidget);
      expect(find.text('Python'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Yeni Piyano')).dy,
        lessThan(tester.getTopLeft(find.text('Eski Gitar')).dy),
      );
      expect(repo.calls, 1);
      repo.controller.add([
        session('Son oturum', day: 19),
        session('Python', taught: false, day: 18),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Son oturum'), findsOneWidget);
      expect(find.text('Eski Gitar'), findsNothing);
      await tester.tap(find.text('Son oturum'));
      await tester.pumpAndSettle();
      expect(opened, 'Son oturum');
      await tester.tap(find.text('ÖĞRENDİM'));
      await tester.pumpAndSettle();
      expect(find.text('Öğrendiklerim'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Son oturum'), findsNothing);
      expect(repo.calls, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'permission errors are not shown as zero; retry recovers to empty history',
    (tester) async {
      final repo = HistoryRepository();
      addTearDown(repo.controller.close);
      await tester.pumpWidget(app(repo));
      expect(find.text('…'), findsNWidgets(2));
      repo.controller.addError(StateError('permission-denied'));
      await tester.pump();
      expect(find.text('—'), findsNWidgets(2));
      await tester.tap(find.text('ÖĞRENDİM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yeniden dene'));
      await tester.pump();
      expect(repo.calls, 2);
      repo.controller.add([]);
      await tester.pumpAndSettle();
      expect(
        find.text('Henüz tamamladığın bir öğrenme oturumu yok.'),
        findsOneWidget,
      );
      expect(find.text('0'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('history fits a small phone with enlarged Turkish text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = HistoryRepository();
    addTearDown(repo.controller.close);
    await tester.pumpWidget(app(repo));
    repo.controller.add([
      session('Gitar ve ritim çalışması', day: 19),
      session('Tarihsiz çalışma'),
    ]);
    await tester.pump();
    await tester.tap(find.text('ÖĞRETTİM'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tarih bilgisi yok\nTamamlandı · 10 token'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'profile counter opens history and selected session detail offline',
    (tester) async {
      PreviewMode.enable();
      await tester.pumpWidget(const PreviewApp(initialLocation: '/profile'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.text('ÖĞRENDİM'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Öğrendiklerim'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Gitar'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ExchangePage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
