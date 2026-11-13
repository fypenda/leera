import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/motion/motion.dart';
import '../../../core/settings/settings.dart';
import '../../../core/time/today.dart';
import '../application/english_idioms.dart';
import '../application/english_sessions.dart';
import '../domain/idiom.dart';
import '../domain/study_pace.dart';
import 'session_chrome.dart';

/// Today's expression, as a gift: wrapped until something is done today
/// (a session finished, or a review round), then opened once, and kept
/// to review if the person wants.
class IdiomGiftCard extends ConsumerWidget {
  const IdiomGiftCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifts = ref.watch(idiomGiftsProvider);
    final stats = ref.watch(practiceStatsProvider).value;
    if (gifts == null || stats == null) return const SizedBox.shrink();

    final today = ref.watch(todayProvider);
    final idiom = ref.watch(idiomOfTheDayProvider);
    final opened = gifts[today];
    final unlocked = giftUnlocked(
      practisedToday: stats.practisedOn(today),
      reviewedToday: parseReviewDays(
        ref.watch(reviewDaysSettingProvider).value,
      ).contains(today),
    );

    if (opened != null) {
      return _OpenedCard(
        idiom: idiom,
        kept: opened.kept,
        onKeep: (kept) =>
            ref.read(idiomActionsProvider).keep(today, kept: kept),
      );
    }
    return _WrappedCard(
      unlocked: unlocked,
      onOpen: unlocked ? () => openIdiomGift(context, ref) : null,
    );
  }
}

/// Opens today's gift over the page: the box shakes, the lid flies off and
/// the expression rises out of it.
Future<void> openIdiomGift(BuildContext context, WidgetRef ref) {
  final today = ref.read(todayProvider);
  final idiom = ref.read(idiomOfTheDayProvider);
  final actions = ref.read(idiomActionsProvider);
  // Opened as soon as the box is: closing early keeps it.
  unawaited(
    actions.open(today, idiom).catchError((Object e) {
      debugPrint('Opening the expression failed: $e');
    }),
  );
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: AppColors.ink.withValues(alpha: 0.88),
    transitionDuration: motionOn(context)
        ? const Duration(milliseconds: 250)
        : Duration.zero,
    pageBuilder: (dialog, _, _) => _GiftReveal(
      idiom: idiom,
      onKeep: () async {
        try {
          await actions.keep(today, kept: true);
        } on Object catch (e) {
          debugPrint('Keeping the expression failed: $e');
        }
        if (dialog.mounted) Navigator.of(dialog).pop();
      },
      onClose: () => Navigator.of(dialog).pop(),
    ),
  );
}

/// The card before opening: the wrapped box, waiting or ready.
class _WrappedCard extends StatelessWidget {
  const _WrappedCard({required this.unlocked, required this.onOpen});

  final bool unlocked;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('idiom-gift'),
    color: unlocked ? AppColors.coralSoft : AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _Wiggle(
              on: unlocked,
              child: _GiftBox(size: 64, locked: !unlocked),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TODAY'S EXPRESSION",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: AppColors.coralStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked ? 'Your gift is ready' : 'A gift for today',
                    style: const TextStyle(
                      fontFamily: displayFontFamily,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked
                        ? 'An English expression, to open now.'
                        : 'Finish a session or a review to open it.',
                    key: ValueKey(
                      unlocked ? 'idiom-gift-ready' : 'idiom-gift-locked',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (unlocked)
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          ],
        ),
      ),
    ),
  );
}

/// The card once opened: the expression, and whether it is kept.
class _OpenedCard extends StatelessWidget {
  const _OpenedCard({
    required this.idiom,
    required this.kept,
    required this.onKeep,
  });

  final Idiom idiom;
  final bool kept;
  final ValueChanged<bool> onKeep;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('idiom-opened'),
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "TODAY'S EXPRESSION",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: AppColors.coralStrong,
                ),
              ),
            ),
            _LevelChip(idiom.level),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          idiom.expression,
          style: const TextStyle(
            fontFamily: displayFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          idiom.meaning,
          style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.text),
        ),
        const SizedBox(height: 4),
        Text(
          '“${idiom.example}”',
          style: const TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('idiom-keep'),
            onPressed: () {
              Haptics.selection();
              onKeep(!kept);
            },
            icon: Icon(
              kept ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 18,
            ),
            label: Text(kept ? 'In your words to review' : 'Keep it to review'),
          ),
        ),
      ],
    ),
  );
}

class _LevelChip extends StatelessWidget {
  const _LevelChip(this.level);

  final String level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      level,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    ),
  );
}

/// The full-screen opening: shake, lid off, the expression rising.
class _GiftReveal extends StatefulWidget {
  const _GiftReveal({
    required this.idiom,
    required this.onKeep,
    required this.onClose,
  });

  final Idiom idiom;
  final VoidCallback onKeep;
  final VoidCallback onClose;

  @override
  State<_GiftReveal> createState() => _GiftRevealState();
}

class _GiftRevealState extends State<_GiftReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  var _started = false;
  var _lidOff = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionOn(context)) {
      _controller.value = 1;
      _lidOff = true;
      return;
    }
    Haptics.light();
    _controller.addListener(_onTick);
    unawaited(_controller.forward());
  }

  void _onTick() {
    if (!_lidOff && _controller.value >= 0.38) {
      Haptics.success();
      setState(() => _lidOff = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// [t] from [start] to [end], as 0 to 1.
  double _part(double start, double end) =>
      ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final idiom = widget.idiom;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // 0–0.38 the box shakes, harder and harder.
                  final shake = _part(0, 0.38);
                  final angle =
                      math.sin(shake * math.pi * 10) * 0.12 * shake;
                  // 0.38–0.6 the lid flies off.
                  final lid = Curves.easeOutCubic.transform(_part(0.38, 0.6));
                  // 0.45–0.85 the card rises out; the box sinks and fades.
                  final card = Curves.easeOutBack.transform(_part(0.45, 0.85));
                  final box = _part(0.5, 0.8);
                  // 0.85–1 the buttons arrive.
                  final buttons = _part(0.85, 1);

                  return Column(
                    children: [
                      const Spacer(),
                      SizedBox(
                        height: 420,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              bottom: 20 - 40 * box,
                              child: Opacity(
                                opacity: 1 - box,
                                child: Transform.rotate(
                                  angle: angle,
                                  child: _GiftBox(size: 150, lidOpen: lid),
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: card.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 120 * (1 - card)),
                                child: Transform.scale(
                                  scale: 0.6 + 0.4 * card,
                                  child: _IdiomCard(idiom: idiom),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: buttons,
                        child: IgnorePointer(
                          ignoring: buttons < 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              0,
                              AppSpacing.xl,
                              AppSpacing.lg,
                            ),
                            child: Column(
                              children: [
                                BottomActionButton(
                                  buttonKey: const ValueKey('gift-keep'),
                                  label: 'Keep it to review',
                                  icon: Icons.bookmark_add_outlined,
                                  onTap: widget.onKeep,
                                ),
                                TextButton(
                                  key: const ValueKey('gift-close'),
                                  onPressed: widget.onClose,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.background,
                                  ),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_lidOff && motionOn(context))
              const Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiBurst(key: ValueKey('gift-confetti')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The expression, as a card out of the box.
class _IdiomCard extends StatelessWidget {
  const _IdiomCard({required this.idiom});

  final Idiom idiom;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('gift-card'),
    width: 320,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(color: Color(0x55000000), blurRadius: 40, offset: Offset(0, 20)),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "TODAY'S EXPRESSION",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: AppColors.coralStrong,
                ),
              ),
            ),
            _LevelChip(idiom.level),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          idiom.expression,
          style: const TextStyle(
            fontFamily: displayFontFamily,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          idiom.meaning,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '“${idiom.example}”',
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}

/// A wrapped box with a bow; its lid lifts and spins away as [lidOpen]
/// goes from 0 to 1. A lock badge while it cannot be opened.
class _GiftBox extends StatelessWidget {
  const _GiftBox({required this.size, this.lidOpen = 0, this.locked = false});

  final double size;
  final double lidOpen;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final body = locked ? AppColors.surfaceMuted : AppColors.coral;
    final lid = locked ? const Color(0xFFE8D6C8) : AppColors.accent;
    final ribbon = locked ? AppColors.textMuted : AppColors.background;
    final w = size;
    final bodyHeight = size * 0.62;
    final lidHeight = size * 0.22;

    return Semantics(
      image: true,
      label: locked ? 'A wrapped gift, locked' : 'A wrapped gift',
      child: SizedBox(
        width: w * 1.1,
        height: size * 1.05,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // The box.
            Container(
              width: w,
              height: bodyHeight,
              decoration: BoxDecoration(
                color: body,
                borderRadius: BorderRadius.circular(size * 0.08),
              ),
              alignment: Alignment.center,
              child: Container(width: size * 0.14, color: ribbon),
            ),
            // The lid, with its bow.
            Positioned(
              bottom: bodyHeight - 2 + lidOpen * size * 1.4,
              child: Opacity(
                opacity: (1 - lidOpen * 1.2).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: lidOpen * 0.9,
                  child: SizedBox(
                    width: w * 1.1,
                    height: lidHeight + size * 0.2,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: w * 1.1,
                          height: lidHeight,
                          decoration: BoxDecoration(
                            color: lid,
                            borderRadius: BorderRadius.circular(size * 0.07),
                          ),
                          alignment: Alignment.center,
                          child: Container(width: size * 0.14, color: ribbon),
                        ),
                        Positioned(
                          bottom: lidHeight - 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final turn in [-0.5, 0.5])
                                Transform.rotate(
                                  angle: turn,
                                  child: Container(
                                    width: size * 0.22,
                                    height: size * 0.16,
                                    decoration: BoxDecoration(
                                      color: ribbon,
                                      borderRadius: BorderRadius.circular(
                                        size * 0.08,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (locked)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.38,
                  height: size * 0.38,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: size * 0.2,
                    color: AppColors.surface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [child] gives a little wiggle every few seconds while [on].
class _Wiggle extends StatefulWidget {
  const _Wiggle({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  State<_Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<_Wiggle> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(_Wiggle old) {
    super.didUpdateWidget(old);
    _update();
  }

  void _update() {
    if (widget.on && motionOn(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating || _controller.value != 0) {
      _controller
        ..stop()
        ..value = 0;
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
    builder: (context, child) {
      // Still most of the time, then a quick shake in the first 20%.
      final t = _controller.value;
      final angle = t < 0.2 ? math.sin(t / 0.2 * math.pi * 4) * 0.12 : 0.0;
      return Transform.rotate(angle: angle, child: child);
    },
  );
}
