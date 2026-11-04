import '../../../matching/presentation/pages/match_success_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/notifications/data/repositories/notification_repository_factory.dart';
import 'package:coetus/features/notifications/domain/models/app_notification.dart';
import 'package:coetus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:coetus/widgets/coetus_bottom_nav.dart';
import 'package:coetus/widgets/coetus_widgets.dart';
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
  bool _markingAllRead = false;

  final List<String> _filters = const [
    'Tümü',
    'Teklifler',
    'Oturumlar',
    'Mesajlar',
    'Topluluk',
  ];

  String? get _userId => (PreviewMode.enabled
      ? PreviewMode.userId
      : FirebaseAuth.instance.currentUser?.uid);

  List<AppNotification> _filterItems(List<AppNotification> items) {
    if (_selectedFilterIndex == 0) return items;
    return items.where((item) {
      if (_selectedFilterIndex == 1) {
        return item.type == AppNotificationType.offerReceived ||
            item.type == AppNotificationType.offerAccepted ||
            item.type == AppNotificationType.offerRejected;
      }
      if (_selectedFilterIndex == 2) {
        return item.type == AppNotificationType.sessionStarted ||
            item.type == AppNotificationType.learningCompleted ||
            item.type == AppNotificationType.learningRefund;
      }
      if (_selectedFilterIndex == 3) {
        return item.type == AppNotificationType.newMessage;
      }
      if (_selectedFilterIndex == 4) {
        return item.type == AppNotificationType.communityActivity ||
            item.type == AppNotificationType.tokenSupport;
      }
      return true;
    }).toList();
  }

  Future<void> _openNotification(AppNotification item) async {
    try {
      await _repository.markAsRead(item.id);
    } catch (_) {}

    if (!mounted) return;
    if (item.type == AppNotificationType.offerAccepted) {
      var name = 'Yeni arkadaşın';
      var skill = '';
      if (!PreviewMode.enabled) {
        try {
          final match = await FirebaseFirestore.instance
              .collection('matches')
              .doc(item.matchId ?? item.targetId)
              .get();
          name = match.data()?['receiverName'] as String? ?? name;
          skill = match.data()?['skillName'] as String? ?? '';
        } catch (_) {
          /* The celebration can still show without profile details. */
        }
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MatchSuccessPage(
            user: MatchedUser(
              name: name,
              skills: [
                if (skill.isNotEmpty) MatchedSkill(name: skill, emoji: '✨'),
              ],
              learningGoals: const [],
            ),
          ),
        ),
      );
      return;
    }
    final route = _resolveRoute(item);
    context.go(route);
  }

  String _resolveRoute(AppNotification item) {
    final targetId = item.targetId.trim();
    switch (item.targetRoute) {
      case '/find-profile':
        return '/find-profile?user=${Uri.encodeComponent(targetId)}';
      case '/community-post':
        return targetId.isEmpty ? '/matching' : '/community-post/$targetId';
      case '/chat-detail':
        return targetId.isEmpty ? '/chat' : '/chat-detail/$targetId';
      case '/exchange-detail':
        return targetId.isEmpty ? '/exchange' : '/exchange-detail/$targetId';
      case '/chat':
      case '/exchange':
      case '/notifications':
      case '/verification':
        return item.targetRoute;
      default:
        return '/exchange';
    }
  }

  Future<void> _markAllAsRead(List<AppNotification> allItems) async {
    if (_markingAllRead) return;
    final unread = allItems.where((item) => !item.read).toList();
    if (unread.isEmpty) return;

    setState(() => _markingAllRead = true);
    try {
      for (final item in unread) {
        await _repository.markAsRead(item.id);
      }
    } catch (_) {
      // Best-effort: individual failures are swallowed, matching the
      // existing per-item markAsRead error handling in _openNotification.
    } finally {
      if (mounted) setState(() => _markingAllRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: SafeArea(
        bottom: false,
        child: userId == null ? _buildSignedOut() : _buildContent(userId),
      ),
      bottomNavigationBar: const CoetusBottomNav(currentIndex: -1),
    );
  }

  Widget _buildSignedOut() {
    return Column(
      children: [
        _buildHeader(unread: 0, onMarkAllRead: null),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(CoetusSpace.xl),
              child: const CoetusEmptyState(
                icon: Icons.lock_outline,
                title: 'Giriş gerekli',
                message: 'Bildirimlerini görmek için giriş yapmalısın.',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(String userId) {
    return StreamBuilder<List<AppNotification>>(
      stream: _repository.streamUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              _buildHeader(unread: 0, onMarkAllRead: null),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(CoetusSpace.xl),
                    child: CoetusEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Bildirimler yüklenemedi',
                      message: '${snapshot.error}',
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildHeader(unread: 0, onMarkAllRead: null),
              const Expanded(child: CoetusLoadingState()),
            ],
          );
        }

        final allItems = snapshot.data ?? const <AppNotification>[];
        final items = _filterItems(allItems);
        final unreadCount = allItems.where((item) => !item.read).length;
        final groups = groupNotificationsByDay(items);

        return Column(
          children: [
            _buildHeader(
              unread: unreadCount,
              onMarkAllRead: unreadCount == 0
                  ? null
                  : () => _markAllAsRead(allItems),
            ),
            const SizedBox(height: CoetusSpace.md),
            CategoryTabs(
              items: _filters,
              selected: _selectedFilterIndex,
              onChanged: (index) =>
                  setState(() => _selectedFilterIndex = index),
            ),
            const SizedBox(height: CoetusSpace.sm),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState(hasAnyNotifications: allItems.isNotEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        CoetusSpace.screenH,
                        CoetusSpace.sm,
                        CoetusSpace.screenH,
                        CoetusSpace.xxl,
                      ),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                              child: Text(
                                group.label,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            for (final item in group.items)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: CoetusSpace.md,
                                ),
                                child: _NotificationCard(
                                  item: item,
                                  onTap: () => _openNotification(item),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader({required int unread, VoidCallback? onMarkAllRead}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        CoetusSpace.screenH,
        CoetusSpace.lg,
        CoetusSpace.screenH,
        CoetusSpace.xl,
      ),
      decoration: const BoxDecoration(
        color: CoetusColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(CoetusRadius.sheet),
          bottomRight: Radius.circular(CoetusRadius.sheet),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: CoetusSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Bildirimler',
                style: textTheme.headlineSmall?.copyWith(
                  color: CoetusColors.oat,
                ),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: CoetusColors.oat.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(CoetusRadius.chip),
                  ),
                  child: Text(
                    '$unread yeni',
                    style: textTheme.labelMedium?.copyWith(
                      color: CoetusColors.oat,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: CoetusSpace.sm),
          GestureDetector(
            onTap: onMarkAllRead,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: _markingAllRead ? .5 : 1,
              child: Text(
                'Tümünü okundu yap',
                style: textTheme.labelMedium?.copyWith(
                  color: CoetusColors.oat.withValues(
                    alpha: onMarkAllRead == null ? .35 : .75,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool hasAnyNotifications}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CoetusSpace.xl),
        child: hasAnyNotifications
            ? const CoetusEmptyState(
                icon: Icons.notifications_none,
                title: 'Bu kategoride bildirim yok',
                message:
                    'Farklı bir filtre seçerek diğer bildirimlerine bakabilirsin.',
              )
            : const CoetusEmptyState(
                icon: Icons.notifications_none,
                title: 'Henüz bildirim yok',
                message:
                    'Teklifler, oturum güncellemeleri ve mesajların burada görünecek.',
              ),
      ),
    );
  }
}

/// Bildirimleri `createdAt` gününe göre gruplar (Bugün / Dün / eski
/// tarihler). Saf bir yardımcı fonksiyondur — yalnızca bellekteki listeyi
/// işler, ek bir stream/repository çağrısı yapmaz.
List<NotificationDayGroup> groupNotificationsByDay(
  List<AppNotification> items, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final todayKey = DateTime(today.year, today.month, today.day);
  final yesterdayKey = todayKey.subtract(const Duration(days: 1));

  final buckets = <DateTime, List<AppNotification>>{};
  final undated = <AppNotification>[];

  for (final item in items) {
    final createdAt = item.createdAt;
    if (createdAt == null) {
      undated.add(item);
      continue;
    }
    final key = DateTime(createdAt.year, createdAt.month, createdAt.day);
    buckets.putIfAbsent(key, () => <AppNotification>[]).add(item);
  }

  final sortedKeys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));

  final groups = <NotificationDayGroup>[
    for (final key in sortedKeys)
      NotificationDayGroup(
        key == todayKey
            ? 'BUGÜN'
            : key == yesterdayKey
            ? 'DÜN'
            : _formatDayLabel(key),
        buckets[key]!,
      ),
  ];

  if (undated.isNotEmpty) {
    groups.add(NotificationDayGroup('DİĞER', undated));
  }

  return groups;
}

String _formatDayLabel(DateTime date) {
  const months = [
    'OCA',
    'ŞUB',
    'MAR',
    'NİS',
    'MAY',
    'HAZ',
    'TEM',
    'AĞU',
    'EYL',
    'EKİ',
    'KAS',
    'ARA',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

/// Aynı güne ait bildirimleri tutan grup.
class NotificationDayGroup {
  const NotificationDayGroup(this.label, this.items);

  final String label;
  final List<AppNotification> items;
}

class _NotificationVisual {
  const _NotificationVisual(this.icon, this.background, this.foreground);

  final IconData icon;
  final Color background;
  final Color foreground;
}

_NotificationVisual _visualFor(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.communityActivity:
    case AppNotificationType.tokenSupport:
    case AppNotificationType.learningCompleted:
    case AppNotificationType.learningRefund:
      return const _NotificationVisual(
        Icons.auto_awesome,
        CoetusPalette.lime,
        CoetusPalette.purple,
      );
    case AppNotificationType.verificationApproved:
      return const _NotificationVisual(
        Icons.verified,
        CoetusPalette.lime,
        CoetusPalette.purple,
      );
    case AppNotificationType.profileConnection:
    case AppNotificationType.offerReceived:
    case AppNotificationType.offerAccepted:
    case AppNotificationType.offerRejected:
      return const _NotificationVisual(
        Icons.swap_horiz,
        CoetusColors.navyTint,
        CoetusColors.navy,
      );
    case AppNotificationType.sessionStarted:
      return const _NotificationVisual(
        Icons.calendar_today_outlined,
        CoetusColors.plateWarm,
        CoetusColors.navy,
      );
    case AppNotificationType.newMessage:
      return const _NotificationVisual(
        Icons.chat_bubble_outline,
        CoetusColors.navyTint,
        CoetusColors.navy,
      );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = _visualFor(item.type);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(CoetusSpace.lg),
          decoration: BoxDecoration(
            color: item.read
                ? CoetusColors.card.withValues(alpha: .7)
                : CoetusColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: CoetusShadow.subtle,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: visual.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, size: 19, color: visual.foreground),
              ),
              const SizedBox(width: CoetusSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isEmpty
                                ? _fallbackTitle(item.type)
                                : item.title,
                            style: textTheme.titleSmall,
                          ),
                        ),
                        if (!item.read) ...[
                          const SizedBox(width: CoetusSpace.sm),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: CoetusColors.coral,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(item.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: CoetusColors.hint,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                      ),
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

  String _fallbackTitle(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.profileConnection:
        return 'Tanışma isteği';
      case AppNotificationType.communityActivity:
        return 'Paylaşımına yorum geldi';
      case AppNotificationType.tokenSupport:
        return 'Token desteği aldın';
      case AppNotificationType.learningCompleted:
        return 'Oturum tamamlandı';
      case AppNotificationType.learningRefund:
        return 'Oturum iptal isteği';
      case AppNotificationType.verificationApproved:
        return 'Yeteneğin doğrulandı';
      case AppNotificationType.offerReceived:
        return 'Yeni teklif';
      case AppNotificationType.offerAccepted:
        return 'Teklif kabul edildi';
      case AppNotificationType.offerRejected:
        return 'Teklif reddedildi';
      case AppNotificationType.sessionStarted:
        return 'Oturum başladı';
      case AppNotificationType.newMessage:
        return 'Yeni mesaj';
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
