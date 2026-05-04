import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatInterfacePage extends StatefulWidget {
  const ChatInterfacePage({super.key});

  @override
  State<ChatInterfacePage> createState() => _ChatInterfacePageState();
}

class _ChatInterfacePageState extends State<ChatInterfacePage> {
  final TextEditingController _messageController = TextEditingController();

  final String matchedUserName = 'Sofia Rodriguez';
  final String matchedUserSubtitle = 'Spanish • Guitar exchange';

  final List<_Message> _messages = [
    _Message(
      text: 'Hey! So excited we matched! 🎉',
      isMe: false,
      time: '10:30',
    ),
    _Message(
      text: "Me too! I'd love to help you with your guitar practice.",
      isMe: true,
      time: '10:32',
    ),
    _Message(
      text:
          'That sounds amazing. I can help you with Spanish conversation in return.',
      isMe: false,
      time: '10:33',
    ),
    _Message(
      text: 'Perfect. Maybe we can start with a short session tomorrow?',
      isMe: true,
      time: '10:34',
    ),
    _Message(
      text: 'Yes, tomorrow works for me. 3 PM?',
      isMe: false,
      time: '10:35',
    ),
    _Message(
      text: 'Perfect timing! See you then 🎸',
      isMe: true,
      time: '10:36',
    ),
  ];

  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _panel = Color(0xFF16162A);
  static const Color _card = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _green = Color(0xFF22C55E);

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _Message(
          text: text,
          isMe: true,
          time: 'Now',
        ),
      );
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                children: [
                  _buildDateDivider('Today'),
                  const SizedBox(height: 14),
                  ..._messages.map(
                    (message) => _MessageBubble(message: message),
                  ),
                ],
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/chat'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_violet, _indigo]),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _panel, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matchedUserName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    matchedUserSubtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _gray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () => context.go('/chat-escrow'),
            icon: const Icon(Icons.lock_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _border),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: _gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(
          top: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.add_circle_outline,
              color: _gray,
            ),
          ),
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
                  suffixIcon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: _gray,
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
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _Message message;

  const _MessageBubble({required this.message});

  static const Color _card = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

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
          gradient:
              isMe ? const LinearGradient(colors: [_indigo, _violet]) : null,
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
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: Colors.white.withOpacity(0.70),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final String time;

  const _Message({
    required this.text,
    required this.isMe,
    required this.time,
  });
}