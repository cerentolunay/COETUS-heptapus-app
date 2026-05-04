import 'package:coetus/features/credit/escrow_status.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecureChatEscrowPage extends StatelessWidget {
  const SecureChatEscrowPage({super.key});

  static const Color _bg = Color(0xFF0F172A);
  static const Color _panel = Color(0xFF111827);
  static const Color _surface = Color(0xFF172033);
  static const Color _border = Color(0xFF243044);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _green = Color(0xFF4ADE80);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFF87171);
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _muted = Color(0xFF94A3B8);

  static const List<_EscrowPreview> _mockEscrows = [
    _EscrowPreview(
      id: 'escrow_1001',
      skillName: 'Flutter ile MVP Gelistirme',
      partnerName: 'Deniz Erdem',
      credits: 42,
      status: EscrowStatus.locked,
      updatedLabel: 'Bugun 19:20',
    ),
    _EscrowPreview(
      id: 'escrow_1002',
      skillName: 'UI Tasarimi Mentorlugu',
      partnerName: 'Zeynep Karaca',
      credits: 35,
      status: EscrowStatus.pending,
      updatedLabel: 'Dun 21:10',
    ),
    _EscrowPreview(
      id: 'escrow_1003',
      skillName: 'Konusma Odakli Ingilizce',
      partnerName: 'Mert Aydin',
      credits: 24,
      status: EscrowStatus.completed,
      updatedLabel: '28 Nis',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeEscrow = _mockEscrows.first;
    final meta = _EscrowStatusMeta.fromStatus(activeEscrow.status);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  _buildSummary(activeEscrow, meta),
                  const SizedBox(height: 16),
                  _buildTimeline(activeEscrow.status),
                  const SizedBox(height: 16),
                  _buildActionPanel(activeEscrow.status),
                  const SizedBox(height: 22),
                  const Text(
                    'Escrow kayitlari',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._mockEscrows.map(_buildEscrowTile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/chat'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Icon(Icons.lock_outline, color: _cyan),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Secure Escrow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(_EscrowPreview escrow, _EscrowStatusMeta meta) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(meta.icon, color: meta.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        escrow.skillName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        escrow.partnerName,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${escrow.credits} HC',
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(EscrowStatus status) {
    final steps = [
      _TimelineStep('Teklif', 'Taraflar skill ve kredi uzerinde anlasir.'),
      _TimelineStep('Kilit', 'Kredi escrow bakiyesinde bekler.'),
      _TimelineStep('Oturum', 'Session tamamlaninca onay beklenir.'),
      _TimelineStep('Cozum', 'Kredi aktarilir veya iade edilir.'),
    ];
    final activeIndex = _activeTimelineIndex(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isDone = index < activeIndex;
          final isActive = index == activeIndex;
          final color = isDone || isActive ? _cyan : _muted;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == steps.length - 1 ? 0 : 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: color),
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        color: color,
                        size: isDone ? 15 : 8,
                      ),
                    ),
                    if (index != steps.length - 1)
                      Container(width: 1, height: 34, color: _border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          color: isActive ? Colors.white : color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionPanel(EscrowStatus status) {
    final canRelease = status == EscrowStatus.locked;
    final canRefund =
        status == EscrowStatus.pending || status == EscrowStatus.locked;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canRelease ? () {} : null,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Tamamlandi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: const Color(0xFF052E16),
              disabledBackgroundColor: _surface,
              disabledForegroundColor: _muted,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canRefund ? () {} : null,
            icon: const Icon(Icons.undo_outlined),
            label: const Text('Iade'),
            style: OutlinedButton.styleFrom(
              foregroundColor: canRefund ? _amber : _muted,
              side: BorderSide(color: canRefund ? _amber : _border),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEscrowTile(_EscrowPreview escrow) {
    final meta = _EscrowStatusMeta.fromStatus(escrow.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  escrow.skillName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${escrow.partnerName} - ${escrow.updatedLabel}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${escrow.credits} HC',
                style: const TextStyle(
                  color: _cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta.shortLabel,
                style: TextStyle(
                  color: meta.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _activeTimelineIndex(EscrowStatus status) {
    switch (status) {
      case EscrowStatus.pending:
        return 0;
      case EscrowStatus.locked:
        return 1;
      case EscrowStatus.completed:
        return 3;
      case EscrowStatus.refunded:
      case EscrowStatus.cancelled:
        return 3;
    }
  }
}

class _EscrowPreview {
  final String id;
  final String skillName;
  final String partnerName;
  final int credits;
  final EscrowStatus status;
  final String updatedLabel;

  const _EscrowPreview({
    required this.id,
    required this.skillName,
    required this.partnerName,
    required this.credits,
    required this.status,
    required this.updatedLabel,
  });
}

class _EscrowStatusMeta {
  final String title;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color color;

  const _EscrowStatusMeta({
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory _EscrowStatusMeta.fromStatus(EscrowStatus status) {
    switch (status) {
      case EscrowStatus.pending:
        return const _EscrowStatusMeta(
          title: 'Onay bekliyor',
          shortLabel: 'Pending',
          description: 'Teklif olustu, kredi henuz kilitli degil.',
          icon: Icons.hourglass_empty,
          color: SecureChatEscrowPage._amber,
        );
      case EscrowStatus.locked:
        return const _EscrowStatusMeta(
          title: 'Kredi guvende',
          shortLabel: 'Locked',
          description:
              'Kredi escrow bakiyesinde kilitli, oturum onayi bekliyor.',
          icon: Icons.lock_outline,
          color: SecureChatEscrowPage._cyan,
        );
      case EscrowStatus.completed:
        return const _EscrowStatusMeta(
          title: 'Tamamlandi',
          shortLabel: 'Done',
          description: 'Oturum onaylandi ve kredi aktarimi tamamlandi.',
          icon: Icons.verified_outlined,
          color: SecureChatEscrowPage._green,
        );
      case EscrowStatus.refunded:
        return const _EscrowStatusMeta(
          title: 'Iade edildi',
          shortLabel: 'Refunded',
          description: 'Kredi ogrenci bakiyesine geri donduruldu.',
          icon: Icons.undo_outlined,
          color: SecureChatEscrowPage._purple,
        );
      case EscrowStatus.cancelled:
        return const _EscrowStatusMeta(
          title: 'Iptal edildi',
          shortLabel: 'Cancelled',
          description: 'Escrow akisi iptal edildi.',
          icon: Icons.cancel_outlined,
          color: SecureChatEscrowPage._red,
        );
    }
  }
}

class _TimelineStep {
  final String title;
  final String description;

  const _TimelineStep(this.title, this.description);
}
