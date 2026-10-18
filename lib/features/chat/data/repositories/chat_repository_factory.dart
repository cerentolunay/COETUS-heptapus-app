import 'package:coetus/preview/preview_repositories.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/chat_repository.dart';
import 'firebase_chat_repository.dart';
import 'local_chat_repository.dart';

class ChatRepositoryFactory {
  static ChatRepository create() {
    if (PreviewMode.enabled) return PreviewChatRepository();
    if (!PreviewMode.enabled && Firebase.apps.isNotEmpty) {
      return FirebaseChatRepository();
    }

    return const LocalChatRepository();
  }
}
