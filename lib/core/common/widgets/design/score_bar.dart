import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// One criterion of an evaluation, scored out of ten, as a labelled bar.
///
/// Scores of seven and above are drawn in the highlight colour, lower ones
/// in coral, so what needs work stands out.
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.label, required this.score})
    : assert(score >= 0 && score <= 10);

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: textTheme.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: score / 10,
              minHeight: 10,
              color: score >= 7 ? AppColors.highlight : AppColors.coral,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 24,
          child: Text(
            '$score',
            textAlign: TextAlign.end,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
