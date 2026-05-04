import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/chat_repository.dart';
import 'firebase_chat_repository.dart';
import 'local_chat_repository.dart';

class ChatRepositoryFactory {
  static ChatRepository create() {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseChatRepository();
    }

    return const LocalChatRepository();
  }
}
