import '../models/chat_message.dart';
import '../models/chat_thread.dart';

abstract class ChatRepository {
  Stream<List<ChatThread>> streamUserChats(String userId);
  Stream<ChatThread?> streamChat(String chatId, String userId);
  Stream<List<ChatMessage>> streamMessages(String chatId);
  Future<void> sendMessage(String chatId, String senderId, String text);
  Future<void> markMessagesAsRead(String chatId, String userId);
}
