import 'package:coetus/app/theme/coetus_theme.dart';
import 'package:coetus/features/exchange/domain/mutual_exchange.dart';
import 'package:coetus/features/exchange/domain/models/exchange_session.dart';
import 'package:coetus/features/exchange/domain/models/match_offer.dart';
import 'package:coetus/features/exchange/presentation/widgets/mutual_action_dialog.dart';
import 'package:coetus/features/exchange/presentation/widgets/mutual_session_card.dart';
import 'package:coetus/features/profile/domain/learning_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mutual offers resolve participant roles without legacy callable fields',
    () {
      final offer = MatchOffer.fromMap({
        'id': 'mutual',
        'initiatorId': 'a',
        'recipientId': 'b',
        'deposits': {'a': 60, 'b': 40},
      });
      expect(offer.requesterId, 'a');
      expect(offer.receiverId, 'b');
      expect(offer.deposits['b'], 40);
    },
  );
  testWidgets(
    'objection needs an explanation and its dialog can be safely closed',
    (tester) async {
      String? reason;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  reason = await showDialog<String>(
                    context: context,
                    builder: (_) =>
                        const MutualActionDialog(action: MutualAction.dispute),
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();
      expect(find.text('En az 10 karakterle açıkla.'), findsOneWidget);
      expect(reason, isNull);
      await tester.enterText(
        find.byType(TextFormField),
        'Karşılıklı çalışma henüz tamamlanmadı.',
      );
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();
      expect(reason, 'Karşılıklı çalışma henüz tamamlanmadı.');
      expect(tester.takeException(), isNull);
    },
  );
  final start = DateTime.utc(2026, 10, 19, 10);
  MutualExchange state({
    String status = 'active',
    String? disputedBy,
    List<String> votes = const ['a'],
  }) => MutualExchange(
    participants: const ['a', 'b'],
    deposits: const {'a': 60, 'b': 40},
    status: status,
    completionVotes: votes,
    completionRequestedAt: start,
    disputedBy: disputedBy,
  );
  ExchangeSession session(MutualExchange s) => ExchangeSession(
    id: 'one',
    matchId: 'one',
    teacherId: '',
    studentId: '',
    participants: const ['a', 'b'],
    skill: 'Python ↔ Gitar',
    credits: 60,
    funded: true,
    status: ExchangeSessionStatus.fromValue(s.status),
    mutual: s,
  );
  test('reminder and expiry use distinct exact 24/72-hour boundaries', () {
    expect(
      state().dueForReminder(
        start
            .add(const Duration(hours: 24))
            .subtract(const Duration(microseconds: 1)),
      ),
      false,
    );
    expect(state().dueForReminder(start.add(const Duration(hours: 24))), true);
    expect(
      state().dueForExpiry(
        start
            .add(const Duration(hours: 72))
            .subtract(const Duration(microseconds: 1)),
      ),
      false,
    );
    expect(state().dueForExpiry(start.add(const Duration(hours: 72))), true);
    expect(state().dueForReminder(start.add(const Duration(hours: 72))), false);
  });
  test(
    'disputes, no completion request and terminal states never auto-expire',
    () {
      for (final s in [
        state(status: 'disputed', disputedBy: 'b'),
        state(status: 'completed', votes: ['a', 'b']),
        state(status: 'expired'),
        state(votes: []),
      ]) {
        expect(s.dueForExpiry(start.add(const Duration(days: 7))), false);
        expect(s.dueForReminder(start.add(const Duration(days: 7))), false);
      }
    },
  );
  test(
    'expired sessions do not count as teaching or learning; mutual completion counts both roles',
    () {
      final sessions = [
        session(state(status: 'expired')),
        session(state(status: 'completed', votes: ['a', 'b'])),
      ];
      for (final role in LearningHistoryRole.values) {
        expect(
          completedLearningHistory(sessions, 'a', role).map((s) => s.status),
          [ExchangeSessionStatus.completed],
        );
        expect(completedLearningHistory(sessions, 'outsider', role), isEmpty);
      }
    },
  );
  testWidgets(
    'mutual card exposes each contribution, objection and own confirmation on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = MutualExchange(
        participants: const ['a', 'b'],
        deposits: const {'a': 60, 'b': 40},
        status: 'active',
        completionVotes: const ['a'],
        completionRequestedAt: DateTime.now(),
      );
      final actions = <MutualAction>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: coetusTheme(useGoogleFonts: false),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MutualSessionCard(
                session: session(s),
                userId: 'b',
                onAction: actions.add,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Senin katkın: 40 token'), findsOneWidget);
      await tester.tap(find.text('Tamamladık'));
      expect(actions, [MutualAction.complete]);
      final dispute = find.text('Takas tamamlanmadı · İtiraz et');
      await tester.ensureVisible(dispute);
      await tester.tap(dispute);
      expect(actions.last, MutualAction.dispute);
      expect(tester.takeException(), isNull);
    },
  );
}
