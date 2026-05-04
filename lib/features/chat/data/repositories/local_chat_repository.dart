import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/repositories/chat_repository.dart';

class LocalChatRepository implements ChatRepository {
  const LocalChatRepository();

  @override
  Stream<List<ChatThread>> streamUserChats(String userId) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return Stream.value(const []);
  }

  @override
  Future<void> sendMessage(String chatId, String senderId, String text) async {}

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {}
}
