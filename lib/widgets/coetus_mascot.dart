import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme/coetus_tokens.dart';

/// Vector mascot: remains crisp at any size and needs no network or image asset.
class CoetusMascot extends StatefulWidget {
  const CoetusMascot({
    super.key,
    this.size = 180,
    this.celebration,
    this.animate = true,
    this.interactive = true,
  });

  final double size;
  final ValueNotifier<int>? celebration;
  final bool animate;
  final bool interactive;

  @override
  State<CoetusMascot> createState() => _CoetusMascotState();
}

class _CoetusMascotState extends State<CoetusMascot>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );
  late final AnimationController _joy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    widget.celebration?.addListener(_celebrate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _updateMotion();
  }

  @override
  void didUpdateWidget(CoetusMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.celebration != widget.celebration) {
      oldWidget.celebration?.removeListener(_celebrate);
      widget.celebration?.addListener(_celebrate);
    }
    _updateMotion();
  }

  void _updateMotion() {
    if (widget.animate &&
        !_reduceMotion &&
        TickerMode.valuesOf(context).enabled) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
      _idle.value = 0;
      _joy.stop();
      _joy.value = 0;
    }
  }

  void _celebrate() {
    if (!_reduceMotion && widget.animate) _joy.forward(from: 0);
  }

  @override
  void dispose() {
    widget.celebration?.removeListener(_celebrate);
    _idle.dispose();
    _joy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Coetus öğrenme arkadaşı',
    button: widget.interactive,
    onTap: widget.interactive ? _celebrate : null,
    child: GestureDetector(
      excludeFromSemantics: true,
      onTap: widget.interactive ? _celebrate : null,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _joy]),
          builder: (context, child) {
            final phase = _idle.value * math.pi * 2;
            final jump = math.sin(_joy.value * math.pi);
            final bob = math.sin(phase) * 4 - jump * 20;
            final blink = _idle.value > .88 && _idle.value < .92
                ? math.sin((_idle.value - .88) / .04 * math.pi)
                : 0.0;
            return Transform.translate(
              offset: Offset(0, bob),
              child: Transform.rotate(
                angle:
                    math.sin(phase) * .025 +
                    math.sin(_joy.value * math.pi * 2) * .09,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _MascotPainter(
                    blink: blink,
                    wave: math.sin(phase),
                    joy: jump,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter({
    required this.blink,
    required this.wave,
    required this.joy,
  });
  final double blink;
  final double wave;
  final double joy;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    final paint = Paint()..isAntiAlias = true;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 185), width: 112, height: 10),
      paint..color = CoetusPalette.purpleInk.withValues(alpha: .13),
    );
    // A little sprout stands for sharing and growing skills.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(94, 29), width: 17, height: 29),
      paint..color = CoetusPalette.lime,
    );
    canvas.save();
    canvas.translate(109, 24);
    canvas.rotate(.65);
    canvas.drawOval(const Rect.fromLTWH(-10, -17, 20, 34), paint);
    canvas.restore();
    final body = Path()
      ..moveTo(42, 77)
      ..cubicTo(44, 38, 81, 40, 103, 43)
      ..cubicTo(139, 35, 167, 49, 165, 83)
      ..lineTo(170, 139)
      ..cubicTo(172, 172, 143, 178, 103, 174)
      ..cubicTo(60, 181, 30, 165, 34, 138)
      ..close();
    canvas.drawPath(body, paint..color = CoetusPalette.lime);
    canvas.drawOval(const Rect.fromLTWH(44, 163, 35, 15), paint);
    canvas.drawOval(const Rect.fromLTWH(125, 163, 35, 15), paint);
    canvas.save();
    canvas.translate(168, 109);
    canvas.rotate(-.5 + wave * .18 - joy * .9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -19, 17, 42),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.restore();
    canvas.drawOval(const Rect.fromLTWH(23, 106, 20, 33), paint);
    for (final x in [76.0, 127.0]) {
      canvas.save();
      canvas.translate(x, 99);
      canvas.scale(1, math.max(.08, 1 - blink));
      canvas.drawOval(
        const Rect.fromLTWH(-21, -27, 42, 54),
        paint..color = CoetusPalette.cream,
      );
      canvas.drawOval(
        const Rect.fromLTWH(-11, -14, 26, 32),
        paint..color = CoetusPalette.purpleInk,
      );
      canvas.drawCircle(
        const Offset(0, -7),
        6,
        paint..color = CoetusPalette.cream,
      );
      canvas.drawCircle(const Offset(8, 4), 2.5, paint);
      canvas.restore();
    }
    paint
      ..color = CoetusPalette.purpleInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(64, 58, 22, 14),
      math.pi * 1.12,
      math.pi * .7,
      false,
      paint,
    );
    canvas.drawArc(
      const Rect.fromLTWH(116, 57, 22, 14),
      math.pi * 1.12,
      math.pi * .7,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(89, 126, 24, 14 + joy * 7),
      0,
      math.pi,
      false,
      paint,
    );
    paint.style = PaintingStyle.fill;
    canvas.drawOval(
      const Rect.fromLTWH(48, 126, 18, 8),
      paint..color = CoetusPalette.pink.withValues(alpha: .5),
    );
    canvas.drawOval(const Rect.fromLTWH(139, 126, 18, 8), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) =>
      oldDelegate.blink != blink ||
      oldDelegate.wave != wave ||
      oldDelegate.joy != joy;
}

class CoetusLoadingState extends StatelessWidget {
  const CoetusLoadingState({
    super.key,
    this.label = 'Birlikte öğrenmeye hazırlanıyoruz…',
  });
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoetusMascot(size: 88, interactive: false),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    ),
  );
}
