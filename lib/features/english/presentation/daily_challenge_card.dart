import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/motion/motion.dart';

/// The bright invitation to today's English session: a random topic to
/// research, then present.
///
/// Rolling a new topic rolls the die first, a second, with a tap of the
/// phone at each end; continuing a session goes straight on.
class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({
    super.key,
    required this.onStart,
    this.continuing = false,
  });

  final VoidCallback onStart;

  /// A session is already in progress: the card offers to continue it.
  final bool continuing;

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  var _rolling = false;

  Future<void> _start() async {
    if (_rolling) return;
    if (widget.continuing || !motionOn(context)) {
      widget.onStart();
      return;
    }
    Haptics.light();
    setState(() => _rolling = true);
    await Future<void>.delayed(RollingDie.rollDuration);
    if (!mounted) return;
    Haptics.success();
    setState(() => _rolling = false);
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final continuing = widget.continuing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy = constraints.maxWidth >= 480;

        return Container(
          key: const ValueKey('daily-challenge'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.highlight,
            borderRadius: BorderRadius.circular(
              roomy ? AppRadii.xl : AppRadii.lg + 4,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: roomy ? -50 : -40,
                top: roomy ? -50 : -40,
                child: Container(
                  width: roomy ? 220 : 150,
                  height: roomy ? 220 : 150,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: roomy ? 40 : 22,
                top: roomy ? 36 : 22,
                child: RollingDie(rolling: _rolling, size: roomy ? 76 : 52),
              ),
              Padding(
                padding: EdgeInsets.all(roomy ? 32 : AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S CHALLENGE",
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: roomy ? 400 : 230,
                      ),
                      child: Text(
                        'A random topic. You research, you explain.',
                        style: TextStyle(
                          fontFamily: displayFontFamily,
                          fontSize: roomy ? 36 : 27,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -0.6,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Text(
                        'Research without AI, then speak or write: '
                        'the dice decides.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg + 2),
                    FilledButton(
                      onPressed: _start,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.ink,
                      ),
                      child: Text(
                        continuing
                            ? 'Continue my session →'
                            : _rolling
                            ? 'Rolling…'
                            : 'Roll my topic →',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
