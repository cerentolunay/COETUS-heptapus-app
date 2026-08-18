import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/credit/escrow_status.dart';
import 'package:coetus/widgets/coetus_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecureChatEscrowPage extends StatelessWidget {
  const SecureChatEscrowPage({super.key});

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
      backgroundColor: CoetusColors.oat,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CoetusSpace.screenH,
                  18,
                  CoetusSpace.screenH,
                  28,
                ),
                children: [
                  _buildSummary(context, activeEscrow, meta),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CoetusColors.card,
                      borderRadius: BorderRadius.circular(CoetusRadius.card),
                      boxShadow: CoetusShadow.card,
                    ),
                    child: EscrowSteps(
                      labels: const ['Teklif', 'Kilit', 'Oturum', 'Çözüm'],
                      currentIndex: _activeTimelineIndex(activeEscrow.status),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionPanel(activeEscrow.status),
                  const SizedBox(height: 22),
                  Text(
                    'Escrow kayıtları',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._mockEscrows.map((escrow) => _buildEscrowTile(context, escrow)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: CoetusColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 16, 14),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go('/chat'),
                icon: const Icon(
                  Icons.chevron_left,
                  color: CoetusColors.oat,
                  size: 26,
                ),
              ),
              const Icon(Icons.lock_outline, color: CoetusColors.oat),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Güvenli Escrow',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: CoetusColors.oat),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    _EscrowPreview escrow,
    _EscrowStatusMeta meta,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoetusColors.card,
        borderRadius: BorderRadius.circular(CoetusRadius.card),
        boxShadow: CoetusShadow.card,
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
                    Text(meta.title, style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(meta.description, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CoetusColors.plateWarm,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(escrow.skillName, style: textTheme.titleMedium),
                      const SizedBox(height: 5),
                      Text(escrow.partnerName, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                CreditBadge(amount: escrow.credits),
              ],
            ),
          ),
        ],
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
            label: const Text('Tamamlandı'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CoetusColors.success,
              foregroundColor: Colors.white,
              disabledBackgroundColor: CoetusColors.card,
              disabledForegroundColor: CoetusColors.hint,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CoetusRadius.button),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canRefund ? () {} : null,
            icon: const Icon(Icons.undo_outlined),
            label: const Text('İade'),
            style: OutlinedButton.styleFrom(
              foregroundColor: canRefund
                  ? CoetusColors.amberDeep
                  : CoetusColors.hint,
              side: BorderSide(
                color: canRefund ? CoetusColors.amberDeep : CoetusColors.border,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CoetusRadius.button),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEscrowTile(BuildContext context, _EscrowPreview escrow) {
    final meta = _EscrowStatusMeta.fromStatus(escrow.status);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoetusColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: CoetusShadow.subtle,
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
                Text(escrow.skillName, style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${escrow.partnerName} · ${escrow.updatedLabel}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CreditBadge(amount: escrow.credits, dense: true),
              const SizedBox(height: 6),
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

  static int _activeTimelineIndex(EscrowStatus status) {
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
          shortLabel: 'Bekliyor',
          description: 'Teklif oluştu, kredi henüz kilitli değil.',
          icon: Icons.hourglass_empty,
          color: CoetusColors.amberDeep,
        );
      case EscrowStatus.locked:
        return const _EscrowStatusMeta(
          title: 'Kredi güvende',
          shortLabel: 'Kilitli',
          description:
              'Kredi escrow bakiyesinde kilitli, oturum onayı bekliyor.',
          icon: Icons.lock_outline,
          color: CoetusColors.amberDeep,
        );
      case EscrowStatus.completed:
        return const _EscrowStatusMeta(
          title: 'Tamamlandı',
          shortLabel: 'Tamamlandı',
          description: 'Oturum onaylandı ve kredi aktarımı tamamlandı.',
          icon: Icons.verified_outlined,
          color: CoetusColors.successDeep,
        );
      case EscrowStatus.refunded:
        return const _EscrowStatusMeta(
          title: 'İade edildi',
          shortLabel: 'İade edildi',
          description: 'Kredi öğrenci bakiyesine geri döndürüldü.',
          icon: Icons.undo_outlined,
          color: CoetusColors.danger,
        );
      case EscrowStatus.cancelled:
        return const _EscrowStatusMeta(
          title: 'İptal edildi',
          shortLabel: 'İptal edildi',
          description: 'Escrow akışı iptal edildi.',
          icon: Icons.cancel_outlined,
          color: CoetusColors.danger,
        );
    }
  }
}
