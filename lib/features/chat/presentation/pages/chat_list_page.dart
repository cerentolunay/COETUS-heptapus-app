import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/chat/data/repositories/chat_repository_factory.dart';
import 'package:coetus/features/chat/domain/models/chat_thread.dart';
import 'package:coetus/features/chat/domain/repositories/chat_repository.dart';
import 'package:coetus/widgets/coetus_bottom_nav.dart';
import 'package:coetus/widgets/coetus_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key, this.repository});
  final ChatRepository? repository;

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ChatRepository _repository =
      widget.repository ?? ChatRepositoryFactory.create();
  Stream<List<ChatThread>>? _chatsStream;
  String? _streamUserId;
  String _lastSearchQuery = '';
  int _selectedTab = 0;

  static const List<String> _tabs = [
    'Tümü',
    'Aktif takas',
    'Talepler',
    'Arşiv',
  ];

  /// Sekmeleri gerçek `ChatThread.status` değerlerine eşler. Kod tabanında
  /// bugüne kadar yazılan tek değerler `'active'` (teklif kabul edilince) ve
  /// `'pending'` (teklif gönderilince) — bu yüzden "Aktif takas" ve
  /// "Talepler" gerçek verilerle çalışır. "Arşiv" için kalıcı bir durum
  /// değeri bulunmadığından, eşleşmeyen ve zarifçe boş duruma düşen bir
  /// alt metin filtresi olarak bırakılmıştır (yeni bir durum değeri icat
  /// edilmez).
  static const List<String> _tabStatusKeywords = [
    '',
    'active',
    'pending',
    'arşiv',
  ];

  String? get _userId => (PreviewMode.enabled
      ? PreviewMode.userId
      : FirebaseAuth.instance.currentUser?.uid);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    if (userId != null && userId != _streamUserId) {
      _streamUserId = userId;
      _chatsStream = _repository.streamUserChats(userId);
    }

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: userId == null
          ? SafeArea(
              child: _buildState(
                icon: Icons.lock_outline,
                title: 'Giriş gerekli',
                subtitle: 'Mesajlarını görmek için giriş yapmalısın.',
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                CategoryTabs(
                  items: _tabs,
                  selected: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildContent(userId)),
                const CoetusBottomNav(currentIndex: 1),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: CoetusColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CoetusSpace.screenH,
            18,
            CoetusSpace.screenH,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sohbetler',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: CoetusColors.oat),
              ),
              TextButton.icon(
                onPressed: () => context.push('/find-profile'),
                icon: const Icon(Icons.person_search_outlined),
                label: const Text('Kullanıcı adı veya QR ile bul'),
                style: TextButton.styleFrom(
                  foregroundColor: CoetusPalette.lime,
                ),
              ),
              const SizedBox(height: 14),
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: CoetusColors.oat.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        border: Border.all(color: CoetusColors.oat.withValues(alpha: .18)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          if (_lastSearchQuery != value.trim()) {
            setState(() {
              _lastSearchQuery = value.trim();
            });
          }
        },
        style: const TextStyle(color: CoetusColors.oat, fontSize: 14),
        cursorColor: CoetusColors.oat,
        decoration: InputDecoration(
          filled: false,
          prefixIcon: Icon(
            Icons.search,
            color: CoetusColors.oat.withValues(alpha: .7),
          ),
          hintText: 'İsim veya yetenek ara',
          hintStyle: TextStyle(
            color: CoetusColors.oat.withValues(alpha: .55),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildContent(String userId) {
    return StreamBuilder<List<ChatThread>>(
      stream: _chatsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildState(
            icon: Icons.cloud_off_outlined,
            title: 'Sohbetler yüklenemedi',
            subtitle: _friendlyErrorMessage(snapshot.error),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CoetusLoadingState();
        }

        final uniqueChats = _deduplicateChatsByParticipant(
          snapshot.data ?? const <ChatThread>[],
          userId,
        );
        final query = _lastSearchQuery.toLowerCase();
        var chats = uniqueChats
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

        final tabKeyword = _tabStatusKeywords[_selectedTab];
        if (tabKeyword.isNotEmpty) {
          chats = chats
              .where((chat) => chat.status.toLowerCase().contains(tabKeyword))
              .toList();
        }

        if (chats.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              CoetusSpace.screenH,
              4,
              CoetusSpace.screenH,
              24,
            ),
            child: CoetusEmptyState(
              icon: Icons.forum_outlined,
              title: uniqueChats.isEmpty ? 'Henüz sohbet yok' : 'Sonuç yok',
              message: uniqueChats.isEmpty
                  ? 'Kabul edilen takaslar burada sohbet olarak görünecek.'
                  : 'Bu filtrede eşleşen bir sohbet bulunamadı.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            CoetusSpace.screenH,
            4,
            CoetusSpace.screenH,
            24,
          ),
          itemCount: chats.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return _ChatListCard(
              chat: chat,
              currentUserId: userId,
              onTap: () => context.go('/chat-detail/${chat.id}'),
            );
          },
        );
      },
    );
  }

  List<ChatThread> _deduplicateChatsByParticipant(
    List<ChatThread> chats,
    String userId,
  ) {
    final latestByParticipant = <String, ChatThread>{};

    for (final chat in chats) {
      final otherId = chat.otherParticipantId(userId);
      final key = otherId.trim().isEmpty ? chat.id : otherId;
      final existing = latestByParticipant[key];

      if (existing == null ||
          _chatSortDate(chat).isAfter(_chatSortDate(existing))) {
        latestByParticipant[key] = chat;
      }
    }

    final uniqueChats = latestByParticipant.values.toList();
    uniqueChats.sort((first, second) {
      return _chatSortDate(second).compareTo(_chatSortDate(first));
    });

    return uniqueChats;
  }

  DateTime _chatSortDate(ChatThread chat) {
    return chat.updatedAt ??
        chat.lastMessageAt ??
        chat.createdAt ??
        DateTime(0);
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
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

  String _friendlyErrorMessage(Object? error) {
    final message = error.toString().toLowerCase();
    if (message.contains('failed-precondition') ||
        message.contains('requires an index')) {
      return 'Sohbet listesi için Firestore index ayarı gerekiyor. Lütfen birazdan tekrar dene.';
    }

    return 'Mesajlar şu an yüklenemiyor. Lütfen tekrar dene.';
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = chat.otherParticipantName(currentUserId);
    final subtitle = chat.lastMessage.isEmpty
        ? (chat.skillName.isEmpty ? 'Henüz mesaj yok' : chat.skillName)
        : chat.lastMessage;

    final hasEscrow = chat.credits > 0 && chat.skillName.isNotEmpty;
    final isPending = chat.status.toLowerCase() == 'pending';
    final String? statusLine = hasEscrow
        ? "${chat.skillName} · ${chat.credits} token escrow'da"
        : (isPending ? 'Teklif onayı bekleniyor' : null);
    final statusColor = hasEscrow
        ? CoetusColors.successDeep
        : CoetusColors.coralDeep;

    return Material(
      color: CoetusColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CoetusColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: CoetusShadow.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
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
                    fontSize: 16,
                  ),
                ),
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
                            style: textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(chat.lastMessageAt ?? chat.updatedAt),
                          style: textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: CoetusColors.muted,
                      ),
                    ),
                    if (statusLine != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        statusLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
