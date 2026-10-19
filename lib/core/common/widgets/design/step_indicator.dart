import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// Where a multi-step flow stands: finished steps, the current one, and the
/// ones still to come, as numbered pills.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.steps,
    required this.current,
    this.onDark = false,
  });

  /// Each step's label, with its emoji if it has one.
  final List<String> steps;

  /// Index of the current step in [steps].
  final int current;

  /// Drawn over a coloured background rather than the page's.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < steps.length; i++)
          Container(
            key: ValueKey('step-$i'),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _background(i),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              '${i + 1} · ${steps[i]}${i < current ? ' ✓' : ''}',
              style: style?.copyWith(color: _foreground(i)),
            ),
          ),
      ],
    );
  }

  Color _background(int index) {
    if (index == current) {
      return onDark ? AppColors.ink : AppColors.highlight;
    }
    if (index < current) {
      return onDark ? AppColors.surface : AppColors.primarySoft;
    }
    return onDark ? AppColors.highlightSoft : AppColors.surfaceMuted;
  }

  Color _foreground(int index) {
    if (index == current && onDark) {
      return AppColors.surface;
    }
    if (index > current && !onDark) {
      return AppColors.textMuted;
    }
    return AppColors.text;
  }
}
