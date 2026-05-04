import 'package:coetus/features/exchange/data/repositories/exchange_repository_factory.dart';
import 'package:coetus/features/exchange/domain/models/exchange_session.dart';
import 'package:coetus/features/exchange/domain/models/match_offer.dart';
import 'package:coetus/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key, this.sessionId});

  final String? sessionId;

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  late final ExchangeRepository _repository = ExchangeRepositoryFactory.create();

  static const Color _bg = Color(0xFF0A0F1C);
  static const Color _bg2 = Color(0xFF0F172A);
  static const Color _bg3 = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _textMuted = Color(0xFF94A3B8);

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _acceptOffer(MatchOffer offer) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _repository.acceptOffer(offer.id, userId);
      _showSnack('Teklif kabul edildi.');
    } catch (error) {
      _showSnack('Teklif kabul edilemedi: $error');
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              ? _buildSignedOutState(context)
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
    return StreamBuilder<List<MatchOffer>>(
      stream: _repository.streamUserOffers(userId),
      builder: (context, offerSnapshot) {
        return StreamBuilder<List<ExchangeSession>>(
          stream: _repository.streamUserSessions(userId),
          builder: (context, sessionSnapshot) {
            if (offerSnapshot.hasError || sessionSnapshot.hasError) {
              return _buildState(
                icon: Icons.cloud_off_outlined,
                title: 'Exchange yuklenemedi',
                subtitle: '${offerSnapshot.error ?? sessionSnapshot.error}',
              );
            }

            if (offerSnapshot.connectionState == ConnectionState.waiting ||
                sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _cyan),
              );
            }

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

            if (pendingOffers.isEmpty && visibleSessions.isEmpty) {
              return _buildState(
                icon: Icons.swap_horiz,
                title: 'Henuz exchange yok',
                subtitle: 'Teklifler ve aktif sessionlar burada gorunecek.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildCreditSummary(visibleSessions),
                  if (pendingOffers.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _buildSectionHeader('Bekleyen Teklifler', Icons.inbox),
                    const SizedBox(height: 12),
                    ...pendingOffers.map(
                      (offer) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OfferCard(
                          offer: offer,
                          isReceiver: offer.receiverId == userId,
                          onAccept: () => _acceptOffer(offer),
                          onReject: () => _rejectOffer(offer),
                        ),
                      ),
                    ),
                  ],
                  if (visibleSessions.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _buildSectionHeader('Sessionlar', Icons.event_available),
                    const SizedBox(height: 12),
                    ...visibleSessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionCard(session: session),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exchange Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tekliflerini ve sessionlarini yonet',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_none, color: _cyan),
        ),
      ],
    );
  }

  Widget _buildCreditSummary(List<ExchangeSession> sessions) {
    final lockedCredits = sessions
        .where(
          (session) =>
              session.status == ExchangeSessionStatus.active ||
              session.status == ExchangeSessionStatus.scheduled,
        )
        .fold<int>(0, (total, session) => total + session.credits);
    final completed = sessions
        .where((session) => session.status == ExchangeSessionStatus.completed)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_violet, _cyan]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: _MiniStat(label: 'Kilitli', value: '$lockedCredits HC'),
          ),
          _MiniStat(label: 'Tamamlanan', value: '$completed'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _cyan, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
            Icon(icon, color: _cyan, size: 44),
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

  Widget _buildSignedOutState(BuildContext context) {
    return _buildState(
      icon: Icons.lock_outline,
      title: 'Giris gerekli',
      subtitle: 'Exchange bilgilerini gormek icin giris yapmalisin.',
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg2.withOpacity(0.86),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => context.go('/profile'),
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            onTap: () => context.go('/chat'),
          ),
          _BottomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Exchange',
            isActive: true,
            onTap: () {},
          ),
        ],
      ),
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
    return _Panel(
      borderColor: _ExchangeColors.amber.withOpacity(0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(
            icon: Icons.handshake_outlined,
            color: _ExchangeColors.amber,
            title: offer.skill.isEmpty ? 'Skill teklifi' : offer.skill,
            status: 'Bekliyor',
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Kredi', value: '${offer.credits} HC'),
          _InfoRow(
            label: isReceiver ? 'Gonderen' : 'Alici',
            value: isReceiver ? offer.requesterId : offer.receiverId,
          ),
          if (isReceiver) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ExchangeColors.red,
                    ),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 12),
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
  const _SessionCard({required this.session});

  final ExchangeSession session;

  @override
  Widget build(BuildContext context) {
    final visual = _SessionVisual.fromStatus(session.status);
    return _Panel(
      borderColor: visual.color.withOpacity(0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(
            icon: visual.icon,
            color: visual.color,
            title: session.skill.isEmpty ? 'Exchange session' : session.skill,
            status: visual.label,
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Kredi', value: '${session.credits} HC'),
          _InfoRow(label: 'Ogretici', value: session.teacherId),
          _InfoRow(label: 'Ogrenci', value: session.studentId),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/exchange-detail/${session.id}'),
                  child: const Text('Detay'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/chat-detail/${session.id}'),
                  child: const Text('Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.borderColor});

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ExchangeColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.status,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: _ExchangeColors.textMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xD9FFFFFF))),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _ExchangeColors.cyan : Colors.white54;
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
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SessionVisual {
  const _SessionVisual({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  factory _SessionVisual.fromStatus(ExchangeSessionStatus status) {
    switch (status) {
      case ExchangeSessionStatus.requested:
        return const _SessionVisual(
          icon: Icons.hourglass_top,
          color: _ExchangeColors.amber,
          label: 'Bekliyor',
        );
      case ExchangeSessionStatus.active:
        return const _SessionVisual(
          icon: Icons.play_circle_outline,
          color: _ExchangeColors.cyan,
          label: 'Aktif',
        );
      case ExchangeSessionStatus.scheduled:
        return const _SessionVisual(
          icon: Icons.event_available_outlined,
          color: _ExchangeColors.violet,
          label: 'Planlandi',
        );
      case ExchangeSessionStatus.completed:
        return const _SessionVisual(
          icon: Icons.check_circle_outline,
          color: _ExchangeColors.green,
          label: 'Tamamlandi',
        );
      case ExchangeSessionStatus.cancelled:
        return const _SessionVisual(
          icon: Icons.cancel_outlined,
          color: _ExchangeColors.red,
          label: 'Iptal edildi',
        );
    }
  }
}

class _ExchangeColors {
  static const Color card = Color(0x14FFFFFF);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color violet = Color(0xFF7C3AED);
  static const Color green = Color(0xFF4ADE80);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFF87171);
  static const Color textMuted = Color(0xFF94A3B8);
}
