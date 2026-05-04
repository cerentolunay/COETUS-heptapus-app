import 'package:coetus/features/chat/data/repositories/chat_repository_factory.dart';
import 'package:coetus/features/chat/domain/models/chat_message.dart';
import 'package:coetus/features/chat/domain/models/chat_thread.dart';
import 'package:coetus/features/chat/domain/repositories/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatInterfacePage extends StatefulWidget {
  const ChatInterfacePage({super.key, this.chatId});

  final String? chatId;

  @override
  State<ChatInterfacePage> createState() => _ChatInterfacePageState();
}

class _ChatInterfacePageState extends State<ChatInterfacePage> {
  final TextEditingController _messageController = TextEditingController();
  late final ChatRepository _repository = ChatRepositoryFactory.create();

  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _panel = Color(0xFF16162A);
  static const Color _card = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _gray = Color(0xFF9CA3AF);

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _sendMessage() async {
    final chatId = widget.chatId;
    final userId = _userId;
    final text = _messageController.text.trim();
    if (chatId == null || userId == null || text.isEmpty) return;

    _messageController.clear();
    try {
      await _repository.sendMessage(chatId, userId, text);
    } catch (error) {
      _messageController.text = text;
      _showSnack('Mesaj gonderilemedi: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = widget.chatId;
    final userId = _userId;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: chatId == null || chatId.isEmpty || userId == null
            ? _buildState(
                icon: Icons.chat_bubble_outline,
                title: 'Chat bulunamadi',
                subtitle: 'Mesajlari gormek icin gecerli bir chat gerekli.',
              )
            : Column(
                children: [
                  _buildChatHeader(context, chatId, userId),
                  Expanded(child: _buildMessages(chatId, userId)),
                  _buildInputBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildMessages(String chatId, String userId) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _repository.streamMessages(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildState(
            icon: Icons.cloud_off_outlined,
            title: 'Mesajlar yuklenemedi',
            subtitle: '${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _indigo));
        }

        final messages = snapshot.data ?? const <ChatMessage>[];
        if (messages.isEmpty) {
          return _buildState(
            icon: Icons.forum_outlined,
            title: 'Henuz mesaj yok',
            subtitle: 'Ilk mesaji gondererek exchange konusmasini baslat.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          children: messages
              .map(
                (message) => _MessageBubble(
                  message: message,
                  isMe: message.senderId == userId,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildChatHeader(
    BuildContext context,
    String chatId,
    String currentUserId,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: StreamBuilder<List<ChatThread>>(
        stream: _repository.streamUserChats(currentUserId),
        builder: (context, snapshot) {
          final chat = (snapshot.data ?? const <ChatThread>[]).where(
            (thread) => thread.id == chatId,
          );
          final thread = chat.isEmpty ? null : chat.first;
          final title =
              thread?.otherParticipantName(currentUserId) ?? 'Exchange Chat';
          final subtitle = thread?.skillName.trim().isNotEmpty == true
              ? thread!.skillName
              : chatId;

          return Row(
            children: [
              IconButton(
                onPressed: () => context.go('/chat'),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_violet, _indigo]),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _gray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go('/chat-escrow'),
                icon: const Icon(Icons.lock_outline, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _indigo, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gray, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: _gray),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_indigo, _violet]),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  static const Color _card = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isMe ? 56 : 0,
          right: isMe ? 0 : 56,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [_indigo, _violet])
              : null,
          color: isMe ? null : _card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.38,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
