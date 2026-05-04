import 'package:coetus/features/notifications/data/repositories/notification_repository_factory.dart';
import 'package:coetus/features/notifications/domain/models/app_notification.dart';
import 'package:coetus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _repository =
      NotificationRepositoryFactory.create();

  int _selectedFilterIndex = 0;

  final List<String> _filters = const [
    'All',
    'Offers',
    'Sessions',
    'Messages',
  ];

  static const Color _bg = Color(0xFF0A0F1C);
  static const Color _bg2 = Color(0xFF0F172A);
  static const Color _bg3 = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _violetSoft = Color(0xFFA78BFA);
  static const Color _textMuted = Color(0xFF94A3B8);

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  List<AppNotification> _filterItems(List<AppNotification> items) {
    if (_selectedFilterIndex == 0) return items;
    return items.where((item) {
      if (_selectedFilterIndex == 1) {
        return item.type == AppNotificationType.offerReceived ||
            item.type == AppNotificationType.offerAccepted ||
            item.type == AppNotificationType.offerRejected;
      }
      if (_selectedFilterIndex == 2) {
        return item.type == AppNotificationType.sessionStarted;
      }
      if (_selectedFilterIndex == 3) {
        return item.type == AppNotificationType.newMessage;
      }
      return true;
    }).toList();
  }

  Future<void> _openNotification(AppNotification item) async {
    try {
      await _repository.markAsRead(item.id);
    } catch (_) {}

    if (!mounted) return;
    final route = _resolveRoute(item);
    context.go(route);
  }

  String _resolveRoute(AppNotification item) {
    final targetId = item.targetId.trim();
    switch (item.targetRoute) {
      case '/chat-detail':
        return targetId.isEmpty ? '/chat' : '/chat-detail/$targetId';
      case '/exchange-detail':
        return targetId.isEmpty ? '/exchange' : '/exchange-detail/$targetId';
      case '/chat':
      case '/exchange':
      case '/notifications':
        return item.targetRoute;
      default:
        return '/exchange';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

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
          child: userId == null
              ? _buildState(
                  icon: Icons.lock_outline,
                  title: 'Giris gerekli',
                  subtitle: 'Bildirimlerini gormek icin giris yapmalisin.',
                )
              : Column(
                  children: [
                    Expanded(child: _buildContent(userId)),
                    _buildBottomNavigation(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContent(String userId) {
    return StreamBuilder<List<AppNotification>>(
      stream: _repository.streamUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildState(
            icon: Icons.cloud_off_outlined,
            title: 'Bildirimler yuklenemedi',
            subtitle: '${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _cyan));
        }

        final allItems = snapshot.data ?? const <AppNotification>[];
        final items = _filterItems(allItems);
        final unreadCount = allItems.where((item) => !item.read).length;

        return SingleChildScrollView(
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
                ...items.map(
                  (item) => _NotificationCard(
                    item: item,
                    onTap: () => _openNotification(item),
                  ),
                ),
            ],
          ),
        );
      },
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildState(
      icon: Icons.notifications_none,
      title: 'Bildirim yok',
      subtitle: 'Teklifler, mesajlar ve session guncellemeleri burada gorunecek.',
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
            Icon(icon, color: _cyan, size: 42),
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
              style: const TextStyle(color: _textMuted, height: 1.5),
            ),
          ],
        ),
      ),
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.read
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title.isEmpty ? _fallbackTitle(item.type) : item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!item.read)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF06B6D4),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.message,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(item.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fallbackTitle(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.offerReceived:
        return 'Yeni teklif';
      case AppNotificationType.offerAccepted:
        return 'Teklif kabul edildi';
      case AppNotificationType.offerRejected:
        return 'Teklif reddedildi';
      case AppNotificationType.sessionStarted:
        return 'Session basladi';
      case AppNotificationType.newMessage:
        return 'Yeni mesaj';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
