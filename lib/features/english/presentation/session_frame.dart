import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/common/widgets/design/step_indicator.dart';
import '../../../core/common/widgets/edge_swipe_back.dart';

/// The full-screen frame of an English session: a way out, where the
/// session stands, an optional action, then the page's two halves, side by
/// side on a wide screen and one above the other on a narrow one.
class SessionFrame extends StatelessWidget {
  const SessionFrame({
    super.key,
    required this.leaveLabel,
    required this.onLeave,
    required this.currentStep,
    required this.start,
    required this.end,
    this.action,
    this.background = AppColors.background,
    this.startFlex = 1,
    this.endFlex = 1,
  });

  /// The steps every session goes through.
  static const steps = ['Research 🔎', 'Present 🎙️', 'Feedback 🧾'];

  /// Wide enough to put the two halves side by side.
  static const double _wideWidth = 900;

  final String leaveLabel;
  final VoidCallback onLeave;
  final int currentStep;
  final Widget start;
  final Widget end;
  final Widget? action;
  final Color background;
  final int startFlex;
  final int endFlex;

  @override
  Widget build(BuildContext context) {
    final onDark = background != AppColors.background;

    return EdgeSwipeBack(
      onBack: onLeave,
      child: Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideWidth;
            final gap = wide ? AppSpacing.xl : AppSpacing.lg + 4;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : AppSpacing.lg + 4,
                vertical: wide ? 32 : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Wraps rather than overflows on a narrow phone or with
                  // large text.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _RoundButton(
                        key: const ValueKey('session-leave'),
                        label: leaveLabel,
                        onTap: onLeave,
                      ),
                      ?action,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StepIndicator(
                    steps: steps,
                    current: currentStep,
                    onDark: onDark,
                  ),
                  SizedBox(height: gap),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: startFlex, child: start),
                        SizedBox(width: gap),
                        Expanded(flex: endFlex, child: end),
                      ],
                    )
                  else ...[
                    start,
                    SizedBox(height: gap),
                    end,
                  ],
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

/// A white, rounded button for the session's top bar.
class SessionTopButton extends StatelessWidget {
  const SessionTopButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      _RoundButton(label: label, onTap: onTap);
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// A white card with the design's large radius.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}
