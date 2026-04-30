import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = const [
    'All',
    'Matches',
    'Sessions',
    'Messages',
  ];

  // Statik renk tanımları
  static const Color _bg = Color(0xFF0A0F1C);
  static const Color _bg2 = Color(0xFF0F172A);
  static const Color _bg3 = Color(0xFF1E1B4B);
  static const Color _card = Color(0x14FFFFFF);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _violetSoft = Color(0xFFA78BFA);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _textSoft = Color(0xFFCBD5E1);

  final List<_NotificationItem> _notifications = const [
    _NotificationItem(
      id: '1',
      title: 'New Match Found',
      message:
          'You matched with Sarah Martinez. Start your first skill swap now.',
      time: '2 min ago',
      type: NotificationType.match,
      isUnread: true,
    ),
    _NotificationItem(
      id: '2',
      title: 'Session Reminder',
      message: 'Your Guitar & Spanish exchange starts tomorrow at 4:00 PM.',
      time: '1 hour ago',
      type: NotificationType.session,
      isUnread: true,
    ),
  ];

  List<_NotificationItem> get _filteredNotifications {
    if (_selectedFilterIndex == 0) return _notifications;
    final filterType = _getFilterTypeForIndex(_selectedFilterIndex);
    return _notifications.where((n) => n.type == filterType).toList();
  }

  NotificationType? _getFilterTypeForIndex(int index) {
    if (index == 1) return NotificationType.match;
    if (index == 2) return NotificationType.session;
    if (index == 3) return NotificationType.message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredNotifications;
    final unreadCount = _notifications.where((n) => n.isUnread).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _bg2, _bg3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(unreadCount),
                      const SizedBox(height: 24),
                      _buildFilterBar(),
                      const SizedBox(height: 24),
                      if (items.isEmpty)
                        _buildEmptyState()
                      else
                        ...items.map((item) => _NotificationCard(item: item)),
                    ],
                  ),
                ),
              ),
              _buildBottomNavigation(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int unread) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _violet.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$unread New',
            style: const TextStyle(
              color: _violetSoft,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: List.generate(_filters.length, (index) {
        final isActive = _selectedFilterIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilterIndex = index),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: [_violet, _cyan])
                  : null,
              color: isActive ? null : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _filters[index],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("No notifications", style: TextStyle(color: _textMuted)),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _bg2,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white54),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.trending_up, color: Colors.white54),
            onPressed: () => context.go('/matching'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: _cyan),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// Alt sınıflar ve Enumlar (Dosya sonuna ekle)
enum NotificationType { match, session, message, escrow, trust }

class _NotificationItem {
  final String id, title, message, time;
  final NotificationType type;
  final bool isUnread;
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isUnread,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.message,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            item.time,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
