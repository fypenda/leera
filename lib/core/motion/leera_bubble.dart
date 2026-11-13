import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'motion.dart';

/// Leera's mascot: the speech bubble of the logo, with a face. It blinks
/// now and then, and nods each time [nods] changes (a choice made, a round
/// finished). Still when the system asks for less motion.
class LeeraBubble extends StatefulWidget {
  const LeeraBubble({
    super.key,
    this.size = 120,
    this.nods = 0,
    this.color = AppColors.background,
    this.semanticLabel = "Leera's bubble, smiling",
  });

  /// Its width; the height follows (110 for 120).
  final double size;

  /// Change it to make the bubble nod.
  final int nods;

  /// The bubble's fill: cream on a dark ground, white on cream.
  final Color color;

  final String? semanticLabel;

  /// Height over width of the drawing.
  static const ratio = 110 / 120;

  @override
  State<LeeraBubble> createState() => _LeeraBubbleState();
}

class _LeeraBubbleState extends State<LeeraBubble>
    with TickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  late final _nod = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Blinking forever only with motion: tests and Reduce Motion stay still.
    if (motionOn(context)) {
      if (!_blink.isAnimating) _blink.repeat();
    } else {
      _blink.stop();
    }
  }

  @override
  void didUpdateWidget(LeeraBubble old) {
    super.didUpdateWidget(old);
    if (old.nods != widget.nods && motionOn(context)) {
      _nod.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    _nod.dispose();
    super.dispose();
  }

  /// The nod: a tilt left, a smaller one right, back; a little bigger.
  static (double, double) _tilt(double t) {
    if (t <= 0 || t >= 1) return (0, 1);
    const left = -12 * math.pi / 180;
    const right = 8 * math.pi / 180;
    if (t < 0.3) {
      final k = Curves.easeOut.transform(t / 0.3);
      return (left * k, 1 + 0.08 * k);
    }
    if (t < 0.65) {
      final k = Curves.easeInOut.transform((t - 0.3) / 0.35);
      return (left + (right - left) * k, 1.08 - 0.08 * k);
    }
    final k = Curves.easeOut.transform((t - 0.65) / 0.35);
    return (right * (1 - k), 1);
  }

  @override
  Widget build(BuildContext context) {
    final bubble = SizedBox(
      width: widget.size,
      height: widget.size * LeeraBubble.ratio,
      child: AnimatedBuilder(
        animation: Listenable.merge([_blink, _nod]),
        builder: (context, _) {
          final (angle, scale) = _tilt(_nod.value);
          // Eyes close briefly between 92% and 100% of each 4 seconds.
          final b = _blink.value;
          final eyes = b < 0.92
              ? 1.0
              : b < 0.95
              ? 1 - 0.9 * (b - 0.92) / 0.03
              : 0.1 + 0.9 * (b - 0.95) / 0.05;
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: CustomPaint(
                painter: _BubblePainter(color: widget.color, eyes: eyes),
              ),
            ),
          );
        },
      ),
    );
    final label = widget.semanticLabel;
    return label == null
        ? ExcludeSemantics(child: bubble)
        : Semantics(image: true, label: label, child: bubble);
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color, required this.eyes});

  final Color color;

  /// How open the eyes are, from 0.1 to 1.
  final double eyes;

  static final _outline = Path()
    ..moveTo(24, 8)
    ..lineTo(96, 8)
    ..arcToPoint(const Offset(116, 28), radius: const Radius.circular(20))
    ..lineTo(116, 68)
    ..arcToPoint(const Offset(96, 88), radius: const Radius.circular(20))
    ..lineTo(52, 88)
    ..lineTo(32, 104)
    ..lineTo(36, 88)
    ..lineTo(24, 88)
    ..arcToPoint(const Offset(4, 68), radius: const Radius.circular(20))
    ..lineTo(4, 28)
    ..arcToPoint(const Offset(24, 8), radius: const Radius.circular(20))
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 120, size.height / 110);

    canvas.drawShadow(_outline, AppColors.ink.withValues(alpha: 0.5), 6, false);
    canvas.drawPath(_outline, Paint()..color = color);

    final ink = Paint()..color = AppColors.ink;
    for (final x in [44.0, 76.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 44), width: 12, height: 12 * eyes),
        ink,
      );
    }
    final cheek = Paint()..color = AppColors.accent.withValues(alpha: 0.55);
    canvas.drawCircle(const Offset(32, 58), 6, cheek);
    canvas.drawCircle(const Offset(88, 58), 6, cheek);
    canvas.drawPath(
      Path()
        ..moveTo(50, 60)
        ..quadraticBezierTo(60, 69, 70, 60),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.eyes != eyes;
}
