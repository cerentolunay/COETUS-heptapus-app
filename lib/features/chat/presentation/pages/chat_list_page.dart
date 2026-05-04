import 'package:coetus/features/chat/data/repositories/chat_repository_factory.dart';
import 'package:coetus/features/chat/domain/models/chat_thread.dart';
import 'package:coetus/features/chat/domain/repositories/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ChatRepository _repository = ChatRepositoryFactory.create();

  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF1A1A2E);
  static const Color _card2 = Color(0xFF16162A);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _indigoText = Color(0xFF818CF8);
  static const Color _gray = Color(0xFF9CA3AF);

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: userId == null
            ? _buildState(
                icon: Icons.lock_outline,
                title: 'Giris gerekli',
                subtitle: 'Mesajlarini gormek icin giris yapmalisin.',
              )
            : Column(
                children: [
                  Expanded(child: _buildContent(userId)),
                  _buildBottomNavigation(context),
                ],
              ),
      ),
    );
  }

  Widget _buildContent(String userId) {
    return StreamBuilder<List<ChatThread>>(
      stream: _repository.streamUserChats(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildState(
            icon: Icons.cloud_off_outlined,
            title: 'Chatler yuklenemedi',
            subtitle: _friendlyErrorMessage(snapshot.error),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _indigoText),
          );
        }

        final query = _searchController.text.trim().toLowerCase();
        final chats = (snapshot.data ?? const <ChatThread>[])
            .where(
              (chat) =>
                  query.isEmpty ||
                  chat.lastMessage.toLowerCase().contains(query) ||
                  chat.id.toLowerCase().contains(query) ||
                  chat.matchId.toLowerCase().contains(query) ||
                  chat.skillName.toLowerCase().contains(query) ||
                  chat
                      .otherParticipantName(userId)
                      .toLowerCase()
                      .contains(query),
            )
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(snapshot.data?.length ?? 0),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              if (chats.isEmpty)
                _buildEmptyChats()
              else
                ...chats.map(
                  (chat) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChatListCard(
                      chat: chat,
                      currentUserId: userId,
                      onTap: () => context.go('/chat-detail/${chat.id}'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int activeCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _indigo.withValues(alpha: 0.20),
                _violet.withValues(alpha: 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _indigo.withValues(alpha: 0.30)),
          ),
          child: Text(
            '$activeCount Active',
            style: const TextStyle(
              color: _indigoText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: _gray),
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: _gray, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyChats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.chat_bubble_outline, color: _gray, size: 34),
          SizedBox(height: 12),
          Text(
            'No conversations found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Accepted exchanges will create chats here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _gray, fontSize: 14),
          ),
        ],
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
            Icon(icon, color: _indigoText, size: 42),
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

  String _friendlyErrorMessage(Object? error) {
    final message = error.toString().toLowerCase();
    if (message.contains('failed-precondition') ||
        message.contains('requires an index')) {
      return 'Chat listesi icin Firestore index ayari gerekiyor. Lutfen birazdan tekrar dene.';
    }

    return 'Mesajlar su an yuklenemiyor. Lutfen tekrar dene.';
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _card2,
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ChatBottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => context.go('/profile'),
          ),
          _ChatBottomNavItem(
            icon: Icons.explore_outlined,
            label: 'Discover',
            onTap: () => context.go('/matching'),
          ),
          _ChatBottomNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            isActive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ChatListCard extends StatelessWidget {
  const _ChatListCard({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  final ChatThread chat;
  final String currentUserId;
  final VoidCallback onTap;

  static const Color _card = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final title = chat.otherParticipantName(currentUserId);
    final subtitle = chat.lastMessage.isEmpty
        ? (chat.skillName.isEmpty ? 'No messages yet' : chat.skillName)
        : chat.lastMessage;

    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_violet, _indigo]),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(chat.lastMessageAt ?? chat.updatedAt),
                          style: const TextStyle(color: _gray, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _gray, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}

class _ChatBottomNavItem extends StatelessWidget {
  const _ChatBottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const Color _active = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _active : Colors.white.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
