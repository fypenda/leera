import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

// The pieces the Leera design repeats on every step of a session: round
// buttons in the top bar, the step dots, the step's eyebrow and the dark
// button at the bottom.

/// A round, white button with an icon, 44 points wide.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Read by VoiceOver: the button shows only its icon.
  final String label;

  /// Null while it cannot be used.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: AppColors.ink),
        ),
      ),
    ),
  );
}

/// Where the session stands: three short bars, those reached in [color].
class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    required this.current,
    this.color = AppColors.highlight,
    this.trackColor = AppColors.surfaceMuted,
  });

  /// 0 for the research, 1 to present, 2 for the correction.
  final int current;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${current + 1} of 3',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var step = 0; step < 3; step++) ...[
          if (step > 0) const SizedBox(width: 6),
          Container(
            width: 28,
            height: 6,
            decoration: BoxDecoration(
              color: step <= current ? color : trackColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    ),
  );
}

/// The small capitals above a step: "STEP 1 · RESEARCH", with its icon.
class StepEyebrow extends StatelessWidget {
  const StepEyebrow({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.textMuted,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: color,
        ),
      ),
    ],
  );
}

/// The dark, full-width button at the bottom of a step.
class BottomActionButton extends StatelessWidget {
  const BottomActionButton({
    super.key,
    this.buttonKey,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  /// The key of the button itself, for tests that read whether it is on.
  final Key? buttonKey;
  final String label;
  final IconData icon;

  /// Null while it cannot be used.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    width: double.infinity,
    child: FilledButton(
      key: buttonKey,
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.surface,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 10),
          Icon(icon, size: 18),
        ],
      ),
    ),
  );
}
