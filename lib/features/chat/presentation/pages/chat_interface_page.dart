import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/chat/data/repositories/chat_repository_factory.dart';
import 'package:coetus/features/chat/domain/models/chat_message.dart';
import 'package:coetus/features/chat/domain/models/chat_thread.dart';
import 'package:coetus/features/chat/domain/repositories/chat_repository.dart';
import 'package:coetus/widgets/coetus_widgets.dart';
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
      backgroundColor: CoetusColors.oat,
      body: chatId == null || chatId.isEmpty || userId == null
          ? SafeArea(
              child: _buildState(
                icon: Icons.chat_bubble_outline,
                title: 'Sohbet bulunamadı',
                subtitle: 'Mesajları görmek için geçerli bir sohbet gerekli.',
              ),
            )
          : Column(
              children: [
                _buildChatHeader(context, chatId, userId),
                Expanded(child: _buildMessages(chatId, userId)),
                SafeArea(top: false, child: _buildInputBar()),
              ],
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
            title: 'Mesajlar yüklenemedi',
            subtitle: '${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: CoetusColors.navy),
          );
        }

        final messages = snapshot.data ?? const <ChatMessage>[];
        if (messages.isEmpty) {
          return _buildState(
            icon: Icons.forum_outlined,
            title: 'Henüz mesaj yok',
            subtitle: 'İlk mesajı göndererek takas konuşmasını başlat.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          children: messages.map((message) {
            if (message.type == ChatMessageType.schedule) {
              return _ScheduleProposalCard(message: message);
            }
            return _MessageBubble(
              message: message,
              isMe: message.senderId == userId,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChatHeader(
    BuildContext context,
    String chatId,
    String currentUserId,
  ) {
    return StreamBuilder<List<ChatThread>>(
      stream: _repository.streamUserChats(currentUserId),
      builder: (context, snapshot) {
        final matches = (snapshot.data ?? const <ChatThread>[]).where(
          (thread) => thread.id == chatId,
        );
        final thread = matches.isEmpty ? null : matches.first;
        final title = thread?.otherParticipantName(currentUserId) ??
            'Takas sohbeti';
        final skillName = thread?.skillName.trim() ?? '';
        final subtitle = skillName.isNotEmpty ? skillName : 'çevrimiçi';
        final credits = thread?.credits ?? 0;

        return Column(
          children: [
            Container(
              color: CoetusColors.navy,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/chat'),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: CoetusColors.oat,
                          size: 26,
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: CoetusColors.plateWarm,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(title),
                          style: const TextStyle(
                            color: CoetusColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: CoetusColors.oat),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: CoetusColors.oat.withValues(alpha: .65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.go('/chat-escrow'),
                        icon: const Icon(
                          Icons.lock_outline,
                          color: CoetusColors.oat,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (skillName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: WarmNotice(
                  trailing: TextButton(
                    onPressed: () => context.go('/chat-escrow'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text('Detay'),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: CoetusColors.ink,
                        fontSize: 12.5,
                      ),
                      children: [
                        const TextSpan(text: 'Aktif takas: '),
                        TextSpan(
                          text: skillName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (credits > 0)
                          TextSpan(text: " · $credits kredi escrow'da"),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CoetusColors.navy, size: 42),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: CoetusColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: CoetusColors.oat,
        border: Border(top: BorderSide(color: CoetusColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: CoetusColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: CoetusColors.border),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: CoetusColors.ink),
                decoration: const InputDecoration(
                  filled: false,
                  hintText: 'Mesaj yaz',
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
                color: CoetusColors.navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: CoetusColors.oat, size: 20),
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

  @override
  Widget build(BuildContext context) {
    final background = isMe ? CoetusColors.navy : CoetusColors.card;
    final foreground = isMe ? CoetusColors.oat : CoetusColors.ink;

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
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: isMe ? null : CoetusShadow.subtle,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: foreground, fontSize: 14, height: 1.38),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: foreground.withValues(alpha: 0.62),
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

/// `ChatMessageType.schedule` mesajları için oturum önerisi kartı.
/// Onaylama/değiştirme için henüz bir repository metodu bulunmadığından
/// butonlar görsel amaçlıdır ve sadece bilgilendirici bir snackbar gösterir.
class _ScheduleProposalCard extends StatelessWidget {
  const _ScheduleProposalCard({required this.message});

  final ChatMessage message;

  void _showPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu özellik yakında aktif olacak.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoetusColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoetusColors.navy, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Oturum önerisi', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(message.text, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showPlaceholder(context),
                  child: const Text('Değiştir'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPlaceholder(context),
                  child: const Text('Onayla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
