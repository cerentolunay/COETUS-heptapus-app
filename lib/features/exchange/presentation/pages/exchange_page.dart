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

class _ExchangePageState extends State<ExchangePage> {
  late final ExchangeRepository _repository =
      ExchangeRepositoryFactory.create();

  static const List<String> _tabs = ['Aktif', 'Bekleyen', 'Geçmiş'];

  int _selectedTab = 0;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _acceptOffer(MatchOffer offer) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _repository.acceptOffer(offer.id, userId);
      _showSnack('Teklif kabul edildi.');
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
    if (_processing.contains(session.id)) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(refund ? 'İptal ve iade isteği' : 'Öğrenme tamamlandı mı?'),
        content: Text(
          refund
              ? 'İki taraf da onayladığında ${session.credits} token öğrenciye iade edilir. İlk onay tek başına iade yapmaz.'
              : '${session.credits} kilitli token öğretmene aktarılacak. Bu işlemi yalnızca oturum tamamlandığında onayla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(refund ? 'İptali onayla' : 'Tamamla ve aktar'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    _processing.add(session.id);
    try {
      await communityCall(
        refund ? 'cancelLearningSession' : 'completeLearningSession',
        {'sessionId': session.id},
      );
      _showSnack(
        refund
            ? 'İptal onayın kaydedildi. İki onay olduğunda iade yapılır.'
            : 'Oturum tamamlandı, token aktarıldı.',
      );
    } catch (e) {
      _showSnack(communityError(e));
    } finally {
      _processing.remove(session.id);
    }
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
    return StreamBuilder<List<MatchOffer>>(
      stream: _repository.streamUserOffers(userId),
      builder: (context, offerSnapshot) {
        return StreamBuilder<List<ExchangeSession>>(
          stream: _repository.streamUserSessions(userId),
          builder: (context, sessionSnapshot) {
            final hasError = offerSnapshot.hasError || sessionSnapshot.hasError;
            final isLoading =
                !hasError &&
                (offerSnapshot.connectionState == ConnectionState.waiting ||
                    sessionSnapshot.connectionState == ConnectionState.waiting);

            final offers = offerSnapshot.data ?? const <MatchOffer>[];
            final sessions = sessionSnapshot.data ?? const <ExchangeSession>[];
            final pendingOffers = offers
                .where((offer) => offer.status == MatchOfferStatus.pending)
                .toList();
            final visibleSessions = widget.sessionId == null
                ? sessions
                : sessions
                      .where((session) => session.id == widget.sessionId)
                      .toList();

            // Kredi özeti — orijinal hesaplama mantığı korunuyor: aktif ya da
            // planlı oturumların kredi toplamı ve tamamlanan oturum sayısı.
            final lockedCredits = visibleSessions
                .where((s) => s.funded && s.studentId == userId)
                .where(
                  (session) =>
                      session.status == ExchangeSessionStatus.active ||
                      session.status == ExchangeSessionStatus.scheduled,
                )
                .fold<int>(0, (total, session) => total + session.credits);
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
                      session.status == ExchangeSessionStatus.scheduled,
                )
                .toList();
            final completedSessions = visibleSessions
                .where(
                  (session) =>
                      session.status == ExchangeSessionStatus.completed ||
                      session.status == ExchangeSessionStatus.cancelled,
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

/// Escrow zaman çizelgesindeki (Anlaşma → Kredi kilitli → Oturum → Aktarım)
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
              CoetusChip('${offer.credits} token', tone: CoetusChipTone.credit),
            ],
          ),
          const SizedBox(height: CoetusSpace.md),
          Text(
            '$otherName · teklif gönderildi, yanıt bekleniyor',
            style: t.bodySmall,
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
  });

  final ExchangeSession session;
  final ValueChanged<ExchangeSession> onMarkCompleted, onRefund;

  @override
  Widget build(BuildContext context) {
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
              labels: const ['Anlaşma', 'Kredi kilitli', 'Oturum', 'Aktarım'],
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
                    FirebaseAuth.instance.currentUser?.uid == session.studentId
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
                      FirebaseAuth.instance.currentUser?.uid,
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
