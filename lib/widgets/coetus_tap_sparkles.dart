import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme/coetus_tokens.dart';

/// Decorative bursts at empty-space taps. Child gestures retain priority.
class CoetusTapSparkles extends StatefulWidget {
  const CoetusTapSparkles({super.key, required this.child});
  final Widget child;
  @override
  State<CoetusTapSparkles> createState() => _CoetusTapSparklesState();
}

class _CoetusTapSparklesState extends State<CoetusTapSparkles> {
  final _bursts = <({int id, Offset origin})>[];
  int _nextId = 0;

  void _burst(TapUpDetails tap) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() {
      // Bound simultaneous animations even when the user taps rapidly.
      if (_bursts.length >= 12) _bursts.removeAt(0);
      _bursts.add((id: _nextId++, origin: tap.localPosition));
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: _burst,
    excludeFromSemantics: true,
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        for (final burst in _bursts)
          Positioned.fill(
            key: ValueKey(burst.id),
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: _TapBurst(
                  origin: burst.origin,
                  onComplete: () {
                    if (mounted) {
                      setState(
                        () => _bursts.removeWhere((b) => b.id == burst.id),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _TapBurst extends StatefulWidget {
  const _TapBurst({required this.origin, required this.onComplete});
  final Offset origin;
  final VoidCallback onComplete;
  @override
  State<_TapBurst> createState() => _TapBurstState();
}

class _TapBurstState extends State<_TapBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 850),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });
  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = _controller.value;
        final spread = Curves.easeOutCubic.transform(t);
        return Stack(
          children: [
            for (var i = 0; i < 10; i++)
              Positioned(
                left:
                    widget.origin.dx +
                    math.cos(i * math.pi * 2 / 10) *
                        spread *
                        (i.isEven ? 62 : 42) -
                    10,
                top:
                    widget.origin.dy +
                    math.sin(i * math.pi * 2 / 10) *
                        spread *
                        (i.isEven ? 62 : 42) -
                    spread * 22 -
                    10,
                child: Opacity(
                  opacity: (1 - t) * .95,
                  child: Transform.scale(
                    scale: .4 + math.sin(t * math.pi) * .8,
                    child: Icon(
                      i % 3 == 0 ? Icons.favorite_rounded : Icons.auto_awesome,
                      size: i.isEven ? 20 : 13,
                      color: CoetusPalette.red,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
