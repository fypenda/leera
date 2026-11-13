import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';

// The small motions that make Leera feel alive: short, never in the way,
// and none at all when iOS asks for less motion (Settings › Accessibility ›
// Motion › Reduce Motion), or in tests.

/// Whether to animate: false when the system asks for less motion.
bool motionOn(BuildContext context) =>
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// The taps the phone gives back.
abstract final class Haptics {
  /// Choosing an option.
  static void selection() => unawaited(HapticFeedback.selectionClick());

  /// Starting something: a roll, a recording.
  static void light() => unawaited(HapticFeedback.lightImpact());

  /// Something arrived or was achieved.
  static void success() => unawaited(HapticFeedback.mediumImpact());
}

/// [child] fades in while rising a little, after [delay].
class RiseIn extends StatefulWidget {
  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
    this.duration = const Duration(milliseconds: 450),
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionOn(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _curve.value) * widget.offset),
        child: child,
      ),
    ),
  );
}

/// [child] gives a small press-and-spring when [selected] turns true.
class SelectPop extends StatefulWidget {
  const SelectPop({super.key, required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  State<SelectPop> createState() => _SelectPopState();
}

class _SelectPopState extends State<SelectPop>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.96), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.03), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.03, end: 1), weight: 30),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(SelectPop old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && motionOn(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// The three bars of the logo, peach, coral and ink.
///
/// With [levels] (three values from 0 to 1) they follow them, as a
/// microphone level; without, they bob one after the other, as Leera's
/// loading sign. Still when the system asks for less motion.
class LogoBars extends StatefulWidget {
  const LogoBars({super.key, this.levels, this.height = 84, this.barWidth = 24});

  final List<double>? levels;

  /// The height of the tallest bar.
  final double height;
  final double barWidth;

  @override
  State<LogoBars> createState() => _LogoBarsState();
}

class _LogoBarsState extends State<LogoBars>
    with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _colors = [AppColors.accent, AppColors.coral, AppColors.ink];

  /// At rest, the bars rise like the logo's.
  static const _rest = [0.5, 0.75, 1.0];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LogoBars old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final bobbing = widget.levels == null && motionOn(context);
    if (bobbing && !_bob.isAnimating) {
      _bob.repeat();
    } else if (!bobbing && _bob.isAnimating) {
      _bob.stop();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.levels;
    final gap = widget.barWidth * 0.55;

    Widget bar(int index, double factor) => Container(
      width: widget.barWidth,
      height: math.max(widget.barWidth, widget.height * factor),
      decoration: BoxDecoration(
        color: _colors[index],
        borderRadius: BorderRadius.circular(widget.barWidth / 2),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) SizedBox(width: gap),
              if (levels != null)
                AnimatedContainer(
                  duration: motionOn(context)
                      ? const Duration(milliseconds: 120)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  width: widget.barWidth,
                  height: math.max(
                    widget.barWidth,
                    widget.height *
                        (0.25 + 0.75 * levels[index].clamp(0.0, 1.0)),
                  ),
                  decoration: BoxDecoration(
                    color: _colors[index],
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                )
              else
                AnimatedBuilder(
                  animation: _bob,
                  builder: (context, _) {
                    if (!_bob.isAnimating) return bar(index, _rest[index]);
                    // Each bar a little after the one before.
                    final phase = (_bob.value - index * 0.17) * 2 * math.pi;
                    return bar(
                      index,
                      _rest[index] * (0.72 + 0.28 * math.sin(phase).abs()),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A burst of confetti from the top centre, once, when it appears. Nothing
/// when the system asks for less motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 34});

  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final List<_Piece> _pieces;
  var _started = false;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    const colors = [
      AppColors.highlight,
      AppColors.accent,
      AppColors.coral,
      AppColors.ink,
      AppColors.accentSoft,
    ];
    _pieces = [
      for (var i = 0; i < widget.pieces; i++)
        _Piece(
          angle: 2 * math.pi * i / widget.pieces + random.nextDouble() * 0.3,
          distance: 120 + random.nextDouble() * 150,
          fall: 160 + random.nextDouble() * 120,
          spin: random.nextDouble() * 4 * math.pi - 2 * math.pi,
          size: 6 + random.nextDouble() * 6,
          round: i % 3 == 0,
          color: colors[i % colors.length],
        ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionOn(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _controller.isAnimating
            ? CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_pieces, _controller.value),
              )
            : const SizedBox.shrink(),
      ),
    ),
  );
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.distance,
    required this.fall,
    required this.spin,
    required this.size,
    required this.round,
    required this.color,
  });

  final double angle;
  final double distance;
  final double fall;
  final double spin;
  final double size;
  final bool round;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.18);
    final out = Curves.easeOutCubic.transform(t);
    final paint = Paint();
    for (final piece in pieces) {
      final position =
          origin +
          Offset(
            math.cos(piece.angle) * piece.distance * out,
            math.sin(piece.angle) * piece.distance * 0.8 * out +
                piece.fall * t * t,
          );
      paint.color = piece.color.withValues(alpha: 1 - t);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(piece.spin * t);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.size,
        height: piece.size * 1.6,
      );
      if (piece.round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// [value] counted up from 0 when it appears, as a whole number.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final TextStyle? style;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (!motionOn(context)) return Text('$value', style: style);
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, shown, _) => Text('${shown.round()}', style: style),
    );
  }
}

/// [child] turns in like a card being flipped, when it appears. Give it a
/// new key to flip again.
class FlipIn extends StatefulWidget {
  const FlipIn({super.key, required this.child});

  final Widget child;

  @override
  State<FlipIn> createState() => _FlipInState();
}

class _FlipInState extends State<FlipIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _turn = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: math.pi / 2.05, end: -0.14), weight: 60),
    TweenSequenceItem(tween: Tween(begin: -0.14, end: 0), weight: 40),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionOn(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: (_controller.value * 2.5).clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(_turn.value),
        child: child,
      ),
    ),
  );
}

/// A die showing five, in the colours of Leera. While [rolling], it leaps
/// and turns twice; otherwise it floats gently. Still when the system asks
/// for less motion.
class RollingDie extends StatefulWidget {
  const RollingDie({super.key, required this.rolling, this.size = 72});

  final bool rolling;
  final double size;

  /// How long a roll lasts.
  static const rollDuration = Duration(milliseconds: 950);

  @override
  State<RollingDie> createState() => _RollingDieState();
}

class _RollingDieState extends State<RollingDie> with TickerProviderStateMixin {
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final _roll = AnimationController(
    vsync: this,
    duration: RollingDie.rollDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionOn(context) && !_float.isAnimating) _float.repeat();
  }

  @override
  void didUpdateWidget(RollingDie old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !old.rolling && motionOn(context)) {
      _roll.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final pip = size * 0.14;

    Widget dot(Alignment alignment) => Align(
      alignment: alignment,
      child: Container(
        width: pip,
        height: pip,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
        ),
      ),
    );

    final face = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.17),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.16),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Stack(
        children: [
          dot(Alignment.topLeft),
          dot(Alignment.topRight),
          dot(Alignment.center),
          dot(Alignment.bottomLeft),
          dot(Alignment.bottomRight),
        ],
      ),
    );

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _roll]),
        child: face,
        builder: (context, child) {
          if (_roll.isAnimating) {
            final t = Curves.easeOutCubic.transform(_roll.value);
            // A leap at first, then the die lands.
            final leap = math.sin(_roll.value * math.pi) * size * 0.3;
            final squash = 1 + 0.15 * math.sin(_roll.value * math.pi * 2);
            return Transform.translate(
              offset: Offset(0, -leap),
              child: Transform.rotate(
                angle: t * 4 * math.pi,
                child: Transform.scale(scale: squash, child: child),
              ),
            );
          }
          final wave = math.sin(_float.value * 2 * math.pi);
          return Transform.translate(
            offset: Offset(0, wave * -4),
            child: Transform.rotate(angle: wave * 0.1, child: child),
          );
        },
      ),
    );
  }
}

/// Builds with [value], grown from 0 when it first appears and eased to
/// any new value after: a ring, a bar, a height.
class GrowTo extends StatelessWidget {
  const GrowTo({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final Widget Function(double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (!motionOn(context)) return builder(value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, shown, _) => builder(shown),
    );
  }
}
