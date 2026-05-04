import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/firebase_chat_repository.dart';
import '../../domain/models/chat_models.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseChatRepository _chatRepository = FirebaseChatRepository();

  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF1A1A2E);
  static const Color _card2 = Color(0xFF16162A);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _indigoText = Color(0xFF818CF8);
  static const Color _gray = Color(0xFF9CA3AF);

  List<_ChatItemData> _filteredChats(List<_ChatItemData> allChats) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return allChats;

    return allChats.where((chat) {
      final matchesName = chat.name.toLowerCase().contains(query);
      final matchesMessage = chat.lastMessage.toLowerCase().contains(query);
      final matchesSkill = chat.skills.any(
        (skill) => skill.toLowerCase().contains(query),
      );
      return matchesName || matchesMessage || matchesSkill;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<List<ChatThread>>(
          stream: _chatRepository.watchThreads(),
          builder: (context, snapshot) {
            final currentUser = _chatRepository.currentUser;
            final allChats = currentUser == null
                ? <_ChatItemData>[]
                : (snapshot.data ?? const <ChatThread>[])
                      .map(
                        (thread) =>
                            _ChatItemData.fromThread(thread, currentUser.uid),
                      )
                      .toList();
            final chats = _filteredChats(allChats);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(allChats.length),
                        const SizedBox(height: 20),
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const _ChatLoadingCard()
                        else if (snapshot.hasError)
                          _ChatErrorCard(
                            message: _mapFirestoreError(snapshot.error),
                          )
                        else
                          _buildChatList(context, chats),
                        const SizedBox(height: 24),
                        _buildTipCard(),
                      ],
                    ),
                  ),
                ),
                _buildBottomNavigation(context),
              ],
            );
          },
        ),
      ),
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

  Widget _buildChatList(BuildContext context, List<_ChatItemData> chats) {
    if (chats.isEmpty) {
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
              'No conversations yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Start from a match offer, then your real messages will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _gray, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: chats
          .map(
            (chat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChatListCard(
                chat: chat,
                onTap: () => context.go('/chat/${chat.id}'),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_card, _card2],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _indigo.withValues(alpha: 0.30)),
      ),
      child: const Column(
        children: [
          _TipIcon(),
          SizedBox(height: 12),
          Text(
            'Tip: Schedule Regular Sessions',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Use the calendar tool to set up recurring skill swaps with your matches',
            textAlign: TextAlign.center,
            style: TextStyle(color: _gray, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
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

  String _mapFirestoreError(Object? error) {
    final message = error.toString();
    if (message.contains('permission-denied')) {
      return 'Chat izinleri eksik. Firestore kurallarini yayinladigindan emin ol.';
    }
    if (message.contains('failed-precondition')) {
      return 'Chat sorgusu icin Firestore index gerekiyor olabilir.';
    }
    return 'Sohbetler yuklenemedi. Lutfen tekrar dene.';
  }
}

class _ChatListCard extends StatelessWidget {
  final _ChatItemData chat;
  final VoidCallback onTap;

  const _ChatListCard({required this.chat, required this.onTap});

  static const Color _card = Color(0xFF1A1A2E);
  static const Color _border = Color(0xFF2A2A3E);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_violet, _indigo]),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (chat.unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [_indigo, _violet]),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${chat.unread}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
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
                            chat.name,
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
                          chat.timestamp,
                          style: const TextStyle(color: _gray, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _gray, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chat.skills
                          .map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x800A0A0F),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _border),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
}

class _ChatLoadingCard extends StatelessWidget {
  const _ChatLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: CircularProgressIndicator(color: Color(0xFF818CF8)),
      ),
    );
  }
}

class _ChatErrorCard extends StatelessWidget {
  final String message;

  const _ChatErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      ),
    );
  }
}

class _ChatBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ChatBottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

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

class _TipIcon extends StatelessWidget {
  const _TipIcon();

  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [_indigo, _violet]),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 24),
    );
  }
}

class _ChatItemData {
  final String id;
  final String name;
  final String lastMessage;
  final String timestamp;
  final int unread;
  final List<String> skills;

  const _ChatItemData({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.unread,
    required this.skills,
  });

  factory _ChatItemData.fromThread(ChatThread thread, String currentUserId) {
    final skills = <String>[
      if (thread.skillName.trim().isNotEmpty) thread.skillName.trim(),
      ...thread.otherUserSkills(currentUserId),
    ].where((skill) => skill.trim().isNotEmpty).toSet().toList();

    return _ChatItemData(
      id: thread.id,
      name: thread.otherUserName(currentUserId),
      lastMessage: thread.lastMessage.isEmpty
          ? 'Sohbet baslatildi.'
          : thread.lastMessage,
      timestamp: _formatTimestamp(thread.updatedAt),
      unread: thread.unreadCount,
      skills: skills,
    );
  }
}

String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final difference = today.difference(date).inDays;

  if (difference == 0) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (difference == 1) return 'Yesterday';
  return '$difference days ago';
}
