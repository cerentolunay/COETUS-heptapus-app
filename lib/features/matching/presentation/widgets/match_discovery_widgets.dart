import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:coetus/app/theme/coetus_tokens.dart';
import 'package:coetus/features/matching/models/match_candidate.dart';

/// The same algorithmic score is used on the orbit and the discovery cards.
/// Discovery-only candidates have no calculated compatibility yet.
String compatibilityLabel(MatchCandidate candidate) =>
    candidate.explanation.skillCompatibilityScore <= 0
    ? 'Yeni'
    : '%${(candidate.matchScore.clamp(0, 1) * 100).round()}';

String? bestMatchUserId(List<MatchCandidate> candidates) {
  final scored =
      candidates
          .where((c) => c.explanation.skillCompatibilityScore > 0)
          .toList()
        ..sort((a, b) {
          final score = b.matchScore.compareTo(a.matchScore);
          return score == 0 ? a.user.id.compareTo(b.user.id) : score;
        });
  return scored.firstOrNull?.user.id;
}

class MatchOrbit extends StatelessWidget {
  const MatchOrbit({
    super.key,
    required this.candidates,
    required this.onSelected,
  });

  final List<MatchCandidate> candidates;
  final ValueChanged<MatchCandidate> onSelected;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final people = candidates
        .where((c) => seen.add(c.user.id))
        .take(6)
        .toList();
    if (people.isEmpty) return const SizedBox.shrink();
    final bestUserId = bestMatchUserId(candidates);

    return _OrbitMotion(
      builder: (context, phase) => Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        decoration: BoxDecoration(
          color: CoetusPalette.purple,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            const Text(
              'Birlikte daha fazlası.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoetusPalette.cream,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Senin yeteneğin, bir başkasının ilhamı.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CoetusPalette.lavender, fontSize: 13),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = math.min(constraints.maxWidth, 360.0);
                final avatarSize = size * .22;
                final radius = size * .36;
                return Center(
                  child: SizedBox.square(
                    dimension: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final fraction in [.52, .75])
                          Container(
                            width: size * fraction,
                            height: size * fraction,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CoetusPalette.lavender.withValues(
                                  alpha: .3,
                                ),
                              ),
                            ),
                          ),
                        SizedBox.square(
                          dimension: size * .39,
                          child: FilledButton(
                            onPressed: () => onSelected(people.first),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              backgroundColor: CoetusPalette.lime,
                              foregroundColor: CoetusPalette.purple,
                              shape: const CircleBorder(),
                            ),
                            child: const FittedBox(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 25),
                                  SizedBox(height: 6),
                                  Text(
                                    'Eşleşmeni\nkeşfet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        for (var i = 0; i < people.length; i++)
                          Positioned(
                            left:
                                size / 2 +
                                radius *
                                    math.cos(
                                      -math.pi / 2 +
                                          i * 2 * math.pi / people.length,
                                    ) -
                                avatarSize / 2,
                            top:
                                size / 2 +
                                math.sin(phase + i) * 2.5 +
                                radius *
                                    math.sin(
                                      -math.pi / 2 +
                                          i * 2 * math.pi / people.length,
                                    ) -
                                avatarSize / 2,
                            child: MatchAvatar(
                              candidate: people[i],
                              highlighted: people[i].user.id == bestUserId,
                              size: avatarSize,
                              onTap: () => onSelected(people[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Profilleri keşfet · Sana uygun yeteneği bul',
              textAlign: TextAlign.center,
              style: TextStyle(color: CoetusPalette.cream, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitMotion extends StatefulWidget {
  const _OrbitMotion({required this.builder});
  final Widget Function(BuildContext, double) builder;

  @override
  State<_OrbitMotion> createState() => _OrbitMotionState();
}

class _OrbitMotionState extends State<_OrbitMotion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          widget.builder(context, _controller.value * math.pi * 2),
    ),
  );
}

class MatchAvatar extends StatelessWidget {
  const MatchAvatar({
    super.key,
    required this.candidate,
    this.size = 72,
    this.onTap,
    this.highlighted = false,
  });
  final MatchCandidate candidate;
  final double size;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final name = candidate.user.name.trim();
    final photo = candidate.user.photoUrl?.trim();
    final label = compatibilityLabel(candidate);
    final fallback = Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: CoetusPalette.purple,
          fontSize: size * .36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label:
          '${name.isEmpty ? 'Kullanıcı' : name}, ${label == 'Yeni' ? 'uyum henüz hesaplanmadı' : '$label uyum'}',
      excludeSemantics: true,
      child: SizedBox(
        width: size + 8,
        height: size + 12,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 12,
              right: 8,
              child: Material(
                color: highlighted ? CoetusPalette.red : CoetusPalette.lavender,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size * .36),
                  side: BorderSide(
                    color: highlighted
                        ? CoetusPalette.red
                        : CoetusPalette.cream,
                    width: highlighted ? 3 : 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: photo == null || photo.isEmpty
                      ? fallback
                      : Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => fallback,
                        ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 3,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: highlighted ? CoetusPalette.red : CoetusPalette.lime,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CoetusPalette.purple, width: 2),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: CoetusPalette.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchProfileCard extends StatelessWidget {
  const MatchProfileCard({
    super.key,
    required this.candidate,
    required this.onTap,
    this.highlighted = false,
  });
  final MatchCandidate candidate;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Material(
    color: highlighted ? CoetusPalette.redSoft : CoetusPalette.cream,
    borderRadius: BorderRadius.circular(26),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MatchAvatar(
              candidate: candidate,
              size: 68,
              onTap: onTap,
              highlighted: highlighted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.user.name.trim().isEmpty
                        ? 'Kullanıcı'
                        : candidate.user.name,
                    style: const TextStyle(
                      color: CoetusPalette.purple,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (highlighted)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '♥ En yüksek uyum',
                        style: TextStyle(
                          color: CoetusPalette.purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Text(
                    '${candidate.teacherSkill.name} öğretiyor',
                    style: const TextStyle(
                      color: CoetusPalette.purple,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        '${candidate.creditsRequired} kredi',
                        style: const TextStyle(
                          color: CoetusPalette.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (candidate.explanation.hasAvailabilityOverlap)
                        const Text(
                          '· Ortak uygun zaman',
                          style: TextStyle(
                            color: CoetusPalette.purple,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_outward_rounded,
              color: CoetusPalette.purple,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
