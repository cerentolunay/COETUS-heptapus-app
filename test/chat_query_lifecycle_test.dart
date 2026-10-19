import 'package:coetus/app/theme/coetus_theme.dart';
import 'package:coetus/features/chat/data/repositories/local_chat_repository.dart';
import 'package:coetus/features/chat/domain/models/chat_message.dart';
import 'package:coetus/features/chat/domain/models/chat_thread.dart';
import 'package:coetus/features/chat/presentation/pages/chat_interface_page.dart';
import 'package:coetus/features/chat/presentation/pages/chat_list_page.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CountingChats extends LocalChatRepository {
  int lists = 0, threads = 0, messages = 0;
  final ids = <String>[];
  @override
  Stream<List<ChatThread>> streamUserChats(String userId) {
    lists++;
    return Stream.value(const []);
  }

  @override
  Stream<ChatThread?> streamChat(String chatId, String userId) {
    threads++;
    ids.add(chatId);
    return Stream.value(
      ChatThread(
        id: chatId,
        sessionId: '',
        matchId: '',
        participants: [userId, 'partner'],
        participantNames: const {'partner': 'Ece'},
      ),
    );
  }

  @override
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    messages++;
    return Stream.value(const [
      ChatMessage(id: 'one', senderId: 'partner', text: 'Merhaba'),
    ]);
  }
}

Widget app(Widget child) =>
    MaterialApp(theme: coetusTheme(useGoogleFonts: false), home: child);

void main() {
  setUp(PreviewMode.enable);
  testWidgets(
    'keyboard rebuild reuses one thread and message subscription; changing chat replaces them',
    (tester) async {
      final repository = CountingChats();
      await tester.pumpWidget(
        app(ChatInterfacePage(chatId: 'first', repository: repository)),
      );
      await tester.pump();
      expect(repository.threads, 1);
      expect(repository.messages, 1);
      expect(repository.lists, 0);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      tester.view.resetViewInsets();
      await tester.pump();
      expect(repository.threads, 1);
      expect(repository.messages, 1);
      await tester.pumpWidget(
        app(ChatInterfacePage(chatId: 'second', repository: repository)),
      );
      await tester.pump();
      expect(repository.ids, ['first', 'second']);
      expect(repository.messages, 2);
      expect(repository.lists, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'search and tab changes filter locally without reopening the chat query',
    (tester) async {
      final repository = CountingChats();
      await tester.pumpWidget(app(ChatListPage(repository: repository)));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Ece');
      await tester.pump();
      await tester.tap(find.text('Aktif takas'));
      await tester.pump();
      expect(repository.lists, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
