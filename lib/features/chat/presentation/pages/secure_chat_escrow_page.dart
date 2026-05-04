import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/firebase_chat_repository.dart';
import '../../domain/models/chat_models.dart';

class SecureChatEscrowPage extends StatefulWidget {
  final String chatId;

  const SecureChatEscrowPage({super.key, required this.chatId});

  @override
  State<SecureChatEscrowPage> createState() => _SecureChatEscrowPageState();
}

class _SecureChatEscrowPageState extends State<SecureChatEscrowPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseChatRepository _chatRepository = FirebaseChatRepository();

  bool _showScheduler = false;
  bool _isSending = false;

  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _bubble = Color(0xFF1E293B);
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _muted = Color(0xFF94A3B8);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _controller.text;
    if (text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _chatRepository.sendTextMessage(chatId: widget.chatId, text: text);
      _controller.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj gonderilemedi. Tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _chatRepository.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<ChatThread?>(
          stream: _chatRepository.watchThread(widget.chatId),
          builder: (context, threadSnapshot) {
            final thread = threadSnapshot.data;

            if (threadSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (threadSnapshot.hasError ||
                thread == null ||
                currentUser == null) {
              return _MissingChat(onBack: () => context.go('/chat'));
            }

            return Column(
              children: [
                _header(thread, currentUser.uid),
                _escrowBanner(thread),
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _chatRepository.watchMessages(widget.chatId),
                    builder: (context, messageSnapshot) {
                      if (messageSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      final messages = messageSnapshot.data ?? const [];
                      return _messages(messages, currentUser.uid);
                    },
                  ),
                ),
                if (_showScheduler) _schedulerPanel(thread),
                _input(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(ChatThread thread, String currentUserId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: Color(0xFF243044))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/chat'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF8B5CF6), _purple]),
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.otherUserName(currentUserId),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (thread.skillName.trim().isNotEmpty)
                  Text(
                    thread.skillName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _escrowBanner(ChatThread thread) {
    if (thread.credits <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _purple.withValues(alpha: 0.18),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${thread.credits} HC locked for ${thread.skillName}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            thread.status,
            style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _messages(List<ChatMessage> messages, String currentUserId) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Henuz mesaj yok. Ilk mesaji gonder ve sohbet gercek zamanli baslasin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.senderId == currentUserId;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.76,
            ),
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isUser ? _purple : _bubble,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        );
      },
    );
  }

  Widget _schedulerPanel(ChatThread thread) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0B1220),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Session schedule request',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _showScheduler = false);
              _sendMessage('${thread.skillName} icin session planlayalim mi?');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _input() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      color: _panel,
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _showScheduler = !_showScheduler),
            icon: const Icon(Icons.calendar_month, color: Colors.white),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0B1220),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _isSending ? null : () => _sendMessage(),
            icon: Icon(
              _isSending ? Icons.hourglass_top : Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingChat extends StatelessWidget {
  final VoidCallback onBack;

  const _MissingChat({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 38,
            ),
            const SizedBox(height: 14),
            const Text(
              'Sohbet bulunamadi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu sohbet silinmis olabilir veya erisim iznin yok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: const Text('Back to chats')),
          ],
        ),
      ),
    );
  }
}
