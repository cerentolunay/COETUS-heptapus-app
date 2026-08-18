import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme/coetus_tokens.dart';

/// Kredi rozeti — dolu lacivert pill, krem yazı.
class CreditBadge extends StatelessWidget {
  const CreditBadge({
    super.key,
    required this.amount,
    this.dense = false,
    this.background = CoetusColors.navy,
    this.foreground = CoetusColors.oat,
  });

  final int amount;
  final bool dense;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final double size = dense ? 10.5 : 12;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 9 : 11, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline, size: size, color: foreground),
          const SizedBox(width: 4),
          Text('$amount',
              style: GoogleFonts.dmSans(
                  fontSize: size, fontWeight: FontWeight.w700, color: foreground)),
        ],
      ),
    );
  }
}

/// Durum çipi: müsait / talep / seviye vb.
class CoetusChip extends StatelessWidget {
  const CoetusChip(this.label,
      {super.key, this.tone = CoetusChipTone.neutral, this.dashed = false});

  final String label;
  final CoetusChipTone tone;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    switch (tone) {
      case CoetusChipTone.neutral:
        bg = CoetusColors.navyTint;
        fg = CoetusColors.navy;
      case CoetusChipTone.success:
        bg = CoetusColors.successSoft;
        fg = CoetusColors.successDeep;
      case CoetusChipTone.warm:
        bg = CoetusColors.coralSoft;
        fg = CoetusColors.coralDeep;
      case CoetusChipTone.credit:
        bg = CoetusColors.amberSoft;
        fg = CoetusColors.amberDeep;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: dashed ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(999),
        border: dashed
            ? Border.all(color: CoetusColors.borderStrong)
            : null,
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dashed ? CoetusColors.navy : fg)),
    );
  }
}

enum CoetusChipTone { neutral, success, warm, credit }

/// Keşif grid kartı — üstte sıcak zemin + lacivert daire içinde kategori
/// ikonu, altta bilgi bloğu.
class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.credits,
    this.statusLabel,
    this.statusTone = CoetusChipTone.success,
    this.plate = CoetusColors.plateWarm,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int credits;
  final String? statusLabel;
  final CoetusChipTone statusTone;
  final Color plate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: CoetusColors.card,
      borderRadius: BorderRadius.circular(CoetusRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoetusRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CoetusRadius.card),
            boxShadow: CoetusShadow.card,
            color: CoetusColors.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 118,
                child: Stack(
                  children: [
                    Container(
                      color: plate,
                      alignment: Alignment.center,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                            color: CoetusColors.navy, shape: BoxShape.circle),
                        child: Icon(icon, size: 30, color: CoetusColors.oat),
                      ),
                    ),
                    if (statusLabel != null)
                      Positioned(
                        left: 9,
                        top: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: CoetusColors.card.withValues(alpha: .92),
                              borderRadius: BorderRadius.circular(999)),
                          child: Text(statusLabel!,
                              style: GoogleFonts.dmSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: statusTone == CoetusChipTone.success
                                      ? CoetusColors.successDeep
                                      : CoetusColors.coralDeep)),
                        ),
                      ),
                    Positioned(
                        right: 9,
                        top: 9,
                        child: CreditBadge(amount: credits, dense: true)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall),
                    const SizedBox(height: 4),
                    Text(subtitle, maxLines: 2, style: t.bodySmall),
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

/// Yatay kaydırılabilir, altı çizili kategori sekmesi.
class CategoryTabs extends StatelessWidget {
  const CategoryTabs(
      {super.key,
      required this.items,
      required this.selected,
      required this.onChanged});

  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: CoetusSpace.xl),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(items[i],
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color:
                            active ? CoetusColors.navy : CoetusColors.hint)),
                const SizedBox(height: 7),
                Container(
                  height: 2.5,
                  width: active ? null : 0,
                  constraints: const BoxConstraints(minWidth: 0),
                  decoration: BoxDecoration(
                      color: active ? CoetusColors.navy : Colors.transparent,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Boş durum.
class CoetusEmptyState extends StatelessWidget {
  const CoetusEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: CoetusColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoetusColors.borderStrong),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
                color: CoetusColors.plateWarm, shape: BoxShape.circle),
            child: Icon(icon, color: CoetusColors.navy, size: 24),
          ),
          const SizedBox(height: 10),
          Text(title, style: t.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          SizedBox(
            width: 230,
            child: Text(message,
                style: t.bodySmall, textAlign: TextAlign.center),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Escrow adım göstergesi (Anlaşma → Kredi kilitli → Oturum → Aktarım).
class EscrowSteps extends StatelessWidget {
  const EscrowSteps(
      {super.key, required this.labels, required this.currentIndex});

  final List<String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final done = i < currentIndex;
      final active = i == currentIndex;
      children.add(Expanded(
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? CoetusColors.navy
                    : active
                        ? CoetusColors.amber
                        : const Color(0x241E3A63),
              ),
              child: done
                  ? const Icon(Icons.check,
                      size: 14, color: CoetusColors.oat)
                  : active
                      ? Center(
                          child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: CoetusColors.card,
                                  shape: BoxShape.circle)))
                      : null,
            ),
            const SizedBox(height: 6),
            Text(labels[i],
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: done
                        ? CoetusColors.navy
                        : active
                            ? CoetusColors.amberDeep
                            : CoetusColors.hint)),
          ],
        ),
      ));
      if (i < labels.length - 1) {
        children.add(Container(
          width: 26,
          height: 2,
          margin: const EdgeInsets.only(bottom: 16),
          color: i < currentIndex
              ? CoetusColors.navy
              : i == currentIndex
                  ? CoetusColors.amber
                  : const Color(0x2E1E3A63),
        ));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

/// Sıcak krem bilgi şeridi (oturum bilgisi, escrow notu).
class WarmNotice extends StatelessWidget {
  const WarmNotice({super.key, required this.child, this.trailing});

  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: CoetusColors.plateWarm,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(child: child),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ]),
    );
  }
}
