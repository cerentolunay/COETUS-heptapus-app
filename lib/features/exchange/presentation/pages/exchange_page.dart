import '../widgets/mutual_action_dialog.dart';
import 'dart:async';
import '../../data/mutual_exchange_service.dart';
import '../../domain/mutual_exchange.dart';
import '../widgets/mutual_session_card.dart';
import '../../../matching/presentation/pages/match_success_page.dart';
import 'package:coetus/preview/preview_mode.dart';
import 'package:coetus/features/community/community.dart';
import 'package:coetus/widgets/coetus_mascot.dart';
import 'package:coetus/features/exchange/data/repositories/exchange_repository_factory.dart';
import 'package:coetus/features/exchange/domain/models/exchange_session.dart';
import 'package:coetus/features/exchange/domain/models/match_offer.dart';
import 'package:coetus/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/coetus_tokens.dart';
import '../../../../widgets/coetus_bottom_nav.dart';
import '../../../../widgets/coetus_widgets.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key, this.sessionId});

  final String? sessionId;

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage>
    with WidgetsBindingObserver {
  late final ExchangeRepository _repository =
      ExchangeRepositoryFactory.create();

  Stream<List<MatchOffer>>? _offerStream;
  Stream<List<ExchangeSession>>? _sessionStream;
  String? _streamUser;
  List<ExchangeSession> _latestSessions = [];
  final _dueAttempts = <String, DateTime>{};
  Timer? _dueTimer;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dueTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _processDue(),
    );
  }

  @override
  void dispose() {
    _dueTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) _processDue();
  }

  Future<void> _processDue() async {
    if (!mounted || !_foreground || PreviewMode.enabled || _userId == null) {
      return;
    }
    final now = DateTime.now();
    for (final session in List<ExchangeSession>.of(_latestSessions)) {
      final state = session.mutual;
      if (state == null) continue;
      final action = state.dueForExpiry(now)
          ? MutualAction.expire
          : state.dueForReminder(now)
          ? MutualAction.remind
          : null;
      if (action == null) continue;
      final key = '${session.id}:${action.name}';
      if (_dueAttempts[key] != null &&
          now.difference(_dueAttempts[key]!) < const Duration(minutes: 5)) {
        continue;
      }
      _dueAttempts[key] = now;
      try {
        await MutualExchangeService().act(session.id, action);
      } catch (_) {
        // Server time decides eligibility. Retry is bounded; no polling query.
      }
    }
  }

  Future<void> _mutualAction(
    ExchangeSession session,
    MutualAction action,
  ) async {
    if (PreviewMode.enabled) {
      _showSnack('Örnek takas; gerçek bakiye veya onay değişmedi.');
      return;
    }
    if (_processing.contains(session.id)) return;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => MutualActionDialog(action: action),
    );
    if (text == null || !mounted) return;
    setState(() => _processing.add(session.id));
    try {
      await MutualExchangeService().act(session.id, action, reason: text);
      if (mounted) _showSnack('Takas durumu güncellendi.');
    } catch (error) {
      if (mounted) {
        _showSnack(
          error is StateError
              ? error.message
              : error is FormatException
              ? error.message
              : 'İşlem doğrulanamadı. Süreyi, bağlantını ve takas durumunu kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(session.id));
    }
  }

  static const List<String> _tabs = ['Aktif', 'Bekleyen', 'Geçmiş'];

  int _selectedTab = 0;

  String? get _userId => (PreviewMode.enabled
      ? PreviewMode.userId
      : FirebaseAuth.instance.currentUser?.uid);

  Future<void> _acceptOffer(MatchOffer offer) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _repository.acceptOffer(offer.id, userId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MatchSuccessPage(
            claimGift: offer.deposits.isEmpty,
            user: MatchedUser(
              name: offer.requesterName,
              skills: const [],
              learningGoals: [MatchedGoal(name: offer.skill, emoji: '✨')],
            ),
          ),
        ),
      );
    } catch (error) {
      _showSnack(communityError(error));
    }
  }

  Future<void> _rejectOffer(MatchOffer offer) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _repository.rejectOffer(offer.id, userId);
      _showSnack('Teklif reddedildi.');
    } catch (error) {
      _showSnack('Teklif reddedilemedi: $error');
    }
  }

  final Set<String> _processing = {};
  Future<void> _sessionAction(ExchangeSession session, bool refund) async {
    if (session.isMutual) {
      await _mutualAction(
        session,
        refund ? MutualAction.cancel : MutualAction.complete,
      );
      return;
    }
    _showSnack(
      'Bu eski sürüme ait bir oturumdur. Kilitli katkılar otomatik dönüştürülmedi; yeni karşılıklı işlemler bu kayıtta çalıştırılmaz.',
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      backgroundColor: CoetusColors.oat,
      body: userId == null ? _buildSignedOutState() : _buildContent(userId),
    );
  }

  Widget _buildContent(String userId) {
    if (_streamUser != userId) {
      _streamUser = userId;
      _offerStream = _repository.streamUserOffers(userId);
      _sessionStream = _repository.streamUserSessions(userId);
    }

    return StreamBuilder<List<MatchOffer>>(
      stream: _offerStream,
      builder: (context, offerSnapshot) {
        return StreamBuilder<List<ExchangeSession>>(
          stream: _sessionStream,
          builder: (context, sessionSnapshot) {
            final hasError = offerSnapshot.hasError || sessionSnapshot.hasError;
            final isLoading =
                !hasError &&
                (offerSnapshot.connectionState == ConnectionState.waiting ||
                    sessionSnapshot.connectionState == ConnectionState.waiting);

            final offers = offerSnapshot.data ?? const <MatchOffer>[];
            final sessions = sessionSnapshot.data ?? const <ExchangeSession>[];
            _latestSessions = sessions;
            if (!PreviewMode.enabled) scheduleMicrotask(_processDue);
            final pendingOffers = offers
                .where((offer) => offer.status == MatchOfferStatus.pending)
                .toList();
            final visibleSessions = widget.sessionId == null
                ? sessions
                : sessions
                      .where((session) => session.id == widget.sessionId)
                      .toList();

            // Token özeti — orijinal hesaplama mantığı korunuyor: aktif ya da
            // planlı oturumların token toplamı ve tamamlanan oturum sayısı.
            final lockedCredits = visibleSessions
                .where((s) => s.funded && (s.isMutual || s.studentId == userId))
                .where(
                  (session) =>
                      session.status == ExchangeSessionStatus.active ||
                      session.status == ExchangeSessionStatus.scheduled ||
                      session.status == ExchangeSessionStatus.disputed,
                )
                .fold<int>(
                  0,
                  (total, session) =>
                      total +
                      (session.mutual?.deposits[userId] ?? session.credits),
                );
            final completedCount = visibleSessions
                .where(
                  (session) =>
                      session.status == ExchangeSessionStatus.completed,
                )
                .length;

            final activeSessions = visibleSessions
                .where(
                  (session) =>
                      session.status == ExchangeSessionStatus.active ||
                      session.status == ExchangeSessionStatus.scheduled ||
                      session.status == ExchangeSessionStatus.disputed,
                )
                .toList();
            final completedSessions = visibleSessions
                .where(
                  (session) =>
                      session.status == ExchangeSessionStatus.completed ||
                      session.status == ExchangeSessionStatus.cancelled ||
                      session.status == ExchangeSessionStatus.expired,
                )
                .toList();

            Widget tabBody;
            if (hasError) {
              tabBody = _buildEmpty(
                icon: Icons.cloud_off_outlined,
                title: 'Takaslar yüklenemedi',
                message: '${offerSnapshot.error ?? sessionSnapshot.error}',
              );
            } else if (isLoading) {
              tabBody = const CoetusLoadingState();
            } else {
              tabBody = _buildTabBody(
                userId: userId,
                pendingOffers: pendingOffers,
                activeSessions: activeSessions,
                completedSessions: completedSessions,
              );
            }

            return Column(
              children: [
                _buildHeader(context, lockedCredits, completedCount),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const SizedBox(height: CoetusSpace.lg),
                        CategoryTabs(
                          items: _tabs,
                          selected:
                              widget.sessionId != null &&
                                  completedSessions.isNotEmpty
                              ? 2
                              : _selectedTab,
                          onChanged: (index) =>
                              setState(() => _selectedTab = index),
                        ),
                        const SizedBox(height: CoetusSpace.md),
                        Expanded(child: tabBody),
                        const CoetusBottomNav(currentIndex: 2),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int lockedCredits,
    int completedCount,
  ) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: CoetusColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(CoetusRadius.sheet),
          bottomRight: Radius.circular(CoetusRadius.sheet),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CoetusSpace.screenH,
            CoetusSpace.md,
            CoetusSpace.screenH,
            CoetusSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Takaslarım',
                      style: t.headlineSmall?.copyWith(color: CoetusColors.oat),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 2),
                    child: Text(
                      'Geçmiş',
                      style: t.labelLarge?.copyWith(
                        color: CoetusColors.oat.withValues(alpha: .85),
                        decoration: TextDecoration.underline,
                        decorationColor: CoetusColors.oat.withValues(alpha: .5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CoetusSpace.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoetusSpace.lg,
                  vertical: CoetusSpace.md,
                ),
                decoration: BoxDecoration(
                  color: CoetusColors.oat.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(CoetusRadius.card),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _HeaderStat(
                        label: 'Kilitli',
                        value: '$lockedCredits token',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: CoetusColors.oat.withValues(alpha: .2),
                    ),
                    const SizedBox(width: CoetusSpace.lg),
                    Expanded(
                      child: _HeaderStat(
                        label: 'Tamamlanan',
                        value: '$completedCount',
                        alignEnd: true,
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

  Widget _buildTabBody({
    required String userId,
    required List<MatchOffer> pendingOffers,
    required List<ExchangeSession> activeSessions,
    required List<ExchangeSession> completedSessions,
  }) {
    switch (widget.sessionId != null && completedSessions.isNotEmpty
        ? 2
        : widget.sessionId != null &&
              pendingOffers.any((o) => o.id == widget.sessionId)
        ? 1
        : _selectedTab) {
      case 1:
        if (pendingOffers.isEmpty) {
          return _buildEmpty(
            icon: Icons.inbox_outlined,
            title: 'Bekleyen teklif yok',
            message: 'Gönderdiğin veya aldığın teklifler burada listelenecek.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            CoetusSpace.screenH,
            0,
            CoetusSpace.screenH,
            CoetusSpace.xl,
          ),
          itemCount: pendingOffers.length,
          separatorBuilder: (_, _) => const SizedBox(height: CoetusSpace.md),
          itemBuilder: (context, index) {
            final offer = pendingOffers[index];
            return _OfferCard(
              offer: offer,
              isReceiver: offer.receiverId == userId,
              onAccept: () => _acceptOffer(offer),
              onReject: () => _rejectOffer(offer),
            );
          },
        );
      case 2:
        if (completedSessions.isEmpty) {
          return _buildEmpty(
            icon: Icons.task_alt_outlined,
            title: 'Henüz tamamlanan takasın yok',
            message: 'Tamamlanan oturumlar burada birikecek.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            CoetusSpace.screenH,
            0,
            CoetusSpace.screenH,
            CoetusSpace.xl,
          ),
          itemCount: completedSessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: CoetusSpace.md),
          itemBuilder: (context, index) => _SessionCard(
            session: completedSessions[index],
            onMarkCompleted: (s) => _sessionAction(s, false),
            onRefund: (s) => _sessionAction(s, true),
            onMutualAction: _mutualAction,
            busy: _processing,
          ),
        );
      default:
        if (activeSessions.isEmpty) {
          return _buildEmpty(
            icon: Icons.swap_horiz,
            title: 'Henüz aktif takasın yok',
            message: 'Kabul edilen teklifler burada oturum halinde görünecek.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            CoetusSpace.screenH,
            0,
            CoetusSpace.screenH,
            CoetusSpace.xl,
          ),
          itemCount: activeSessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: CoetusSpace.md),
          itemBuilder: (context, index) => _SessionCard(
            session: activeSessions[index],
            onMarkCompleted: (s) => _sessionAction(s, false),
            onRefund: (s) => _sessionAction(s, true),
            onMutualAction: _mutualAction,
            busy: _processing,
          ),
        );
    }
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CoetusSpace.screenH),
        child: CoetusEmptyState(icon: icon, title: title, message: message),
      ),
    );
  }

  Widget _buildSignedOutState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(CoetusSpace.xl),
        child: CoetusEmptyState(
          icon: Icons.lock_outline,
          title: 'Giriş gerekli',
          message: 'Takaslarını görmek için giriş yapmalısın.',
        ),
      ),
    );
  }
}

/// Escrow zaman çizelgesindeki (Anlaşma → Token kilitli → Oturum → Aktarım)
/// mevcut adımı hesaplar — `secure_chat_escrow_page.dart`'taki
/// `EscrowStatus` → timeline index eşlemesiyle aynı yaklaşım.
int _sessionTimelineIndex(ExchangeSessionStatus status) {
  switch (status) {
    case ExchangeSessionStatus.requested:
      return 0;
    case ExchangeSessionStatus.active:
      return 1;
    case ExchangeSessionStatus.scheduled:
      return 2;
    case ExchangeSessionStatus.completed:
      return 3;
    case ExchangeSessionStatus.expired:
    case ExchangeSessionStatus.disputed:
    case ExchangeSessionStatus.cancelled:
      // İptal edilen oturumlar hiçbir sekmede gösterilmiyor; yine de
      // eşlemeyi tam tutmak için en erken adıma sabitleniyor.
      return 0;
  }
}

String _shortId(String id) => id.length <= 8 ? id : '${id.substring(0, 8)}…';

String _displayNameOrFallback(String name, String userId) {
  if (name.trim().isNotEmpty) return name.trim();
  return _shortId(userId);
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.labelSmall?.copyWith(
            color: CoetusColors.oat.withValues(alpha: .75),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: t.headlineMedium?.copyWith(color: CoetusColors.oat)),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.isReceiver,
    required this.onAccept,
    required this.onReject,
  });

  final MatchOffer offer;
  final bool isReceiver;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final otherName = isReceiver
        ? _displayNameOrFallback(offer.requesterName, offer.requesterId)
        : _displayNameOrFallback(offer.receiverName, offer.receiverId);

    return Container(
      padding: const EdgeInsets.all(CoetusSpace.lg),
      decoration: BoxDecoration(
        color: CoetusColors.card,
        borderRadius: BorderRadius.circular(CoetusRadius.card),
        boxShadow: CoetusShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: CoetusColors.amberSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: CoetusColors.amberDeep,
                ),
              ),
              const SizedBox(width: CoetusSpace.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    offer.skill.isEmpty ? 'Yetenek teklifi' : offer.skill,
                    style: t.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: CoetusSpace.sm),
              CoetusChip(
                '${offer.deposits[isReceiver ? offer.receiverId : offer.requesterId] ?? offer.credits} token',
                tone: CoetusChipTone.credit,
              ),
            ],
          ),
          const SizedBox(height: CoetusSpace.md),
          Text(
            '$otherName · teklif gönderildi, yanıt bekleniyor',
            style: t.bodySmall,
          ),
          if (offer.deposits.isNotEmpty)
            Text(
              'Senin katkın: ${offer.deposits[isReceiver ? offer.receiverId : offer.requesterId]} · Karşı taraf: ${offer.deposits[isReceiver ? offer.requesterId : offer.receiverId]} token. İkiniz de öğretiyor ve öğreniyorsunuz.',
            ),
          if (isReceiver) ...[
            const SizedBox(height: CoetusSpace.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: CoetusSpace.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Kabul Et'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onMarkCompleted,
    required this.onRefund,
    this.onMutualAction,
    this.busy = const {},
  });

  final ExchangeSession session;
  final ValueChanged<ExchangeSession> onMarkCompleted, onRefund;
  final void Function(ExchangeSession, MutualAction)? onMutualAction;
  final Set<String> busy;

  @override
  Widget build(BuildContext context) {
    if (session.isMutual) {
      return MutualSessionCard(
        session: session,
        userId: PreviewMode.enabled
            ? PreviewMode.userId
            : FirebaseAuth.instance.currentUser?.uid ?? '',
        busy: busy.contains(session.id),
        onChat: () => context.go('/chat-detail/${session.id}'),
        onDetails: () => context.go('/exchange-detail/${session.id}'),
        onAction: (action) => onMutualAction?.call(session, action),
      );
    }
    final t = Theme.of(context).textTheme;
    final timelineIndex = _sessionTimelineIndex(session.status);
    final showActions =
        session.status == ExchangeSessionStatus.active ||
        session.status == ExchangeSessionStatus.scheduled;

    return Container(
      padding: const EdgeInsets.all(CoetusSpace.lg),
      decoration: BoxDecoration(
        color: CoetusColors.card,
        borderRadius: BorderRadius.circular(CoetusRadius.card),
        boxShadow: CoetusShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.skill.isEmpty ? 'Takas oturumu' : session.skill,
                      style: t.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_shortId(session.teacherId)} ↔ '
                      '${_shortId(session.studentId)} · '
                      'Adım ${timelineIndex + 1}/4',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CoetusSpace.sm),
              CoetusChip(
                '${session.credits} token',
                tone: CoetusChipTone.credit,
              ),
            ],
          ),
          const SizedBox(height: CoetusSpace.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => context.go('/exchange-detail/${session.id}'),
                child: const Text('Detay'),
              ),
              TextButton(
                onPressed: () => context.go('/chat-detail/${session.id}'),
                child: const Text('Sohbet'),
              ),
            ],
          ),
          const SizedBox(height: CoetusSpace.sm),
          if (session.status == ExchangeSessionStatus.cancelled)
            const Text(
              'Oturum iptal edildi; kilitli token öğrenciye iade edildi.',
            ),
          if (session.funded &&
              session.status != ExchangeSessionStatus.cancelled)
            EscrowSteps(
              labels: const ['Anlaşma', 'Token kilitli', 'Oturum', 'Aktarım'],
              currentIndex: timelineIndex,
            ),
          if (!session.funded)
            const Text('Bu oturumda token kilidi bulunmuyor.'),
          if (showActions && session.funded) ...[
            const SizedBox(height: CoetusSpace.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (PreviewMode.enabled
                            ? PreviewMode.userId
                            : FirebaseAuth.instance.currentUser?.uid) ==
                        session.studentId
                    ? () => onMarkCompleted(session)
                    : null,
                child: const Text('Tamamla ve tokenı aktar'),
              ),
            ),
            const SizedBox(height: CoetusSpace.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    session.refundVotes.contains(
                      (PreviewMode.enabled
                          ? PreviewMode.userId
                          : FirebaseAuth.instance.currentUser?.uid),
                    )
                    ? null
                    : () => onRefund(session),
                child: Text(
                  session.refundVotes.isEmpty
                      ? 'İptal / iade iste'
                      : 'İptali onayla',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
