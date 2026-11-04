import 'models/chat_message.dart';

class ConversationHeart {
  const ConversationHeart(this.mine, this.theirs);
  final int mine, theirs;
  int get reciprocal => mine < theirs ? mine : theirs;
  int get level => reciprocal >= 500
      ? 2
      : reciprocal >= 50
      ? 1
      : 0;
  double get progress => (reciprocal / (level == 0 ? 50 : 500)).clamp(0, 1);
  static ConversationHeart fromMessages(
    Iterable<ChatMessage> messages,
    String userId,
  ) {
    var mine = 0, theirs = 0;
    final seen = <String>{};
    for (final message in messages) {
      if (message.type != ChatMessageType.text ||
          message.text.trim().isEmpty ||
          !seen.add(message.id)) {
        continue;
      }
      if (message.senderId == userId) {
        mine++;
      } else if (message.senderId.isNotEmpty) {
        theirs++;
      }
    }
    return ConversationHeart(mine, theirs);
  }
}
