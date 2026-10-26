import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// How a theme looks: its icon and its colours.
typedef ThemeStyle = ({IconData icon, Color background, Color foreground});

const _palettes = [
  (background: AppColors.primarySoft, foreground: AppColors.primary),
  (background: AppColors.coralSoft, foreground: AppColors.coralStrong),
  (background: AppColors.accentSoft, foreground: AppColors.accentStrong),
];

const _icons = {
  'History': Icons.account_balance_outlined,
  'Economy': Icons.trending_up_rounded,
  'Environment': Icons.eco_outlined,
  'Africa': Icons.public_rounded,
  'Science': Icons.science_outlined,
  'Health': Icons.favorite_border_rounded,
  'Technology': Icons.memory_rounded,
  'Philosophy': Icons.psychology_outlined,
  'Geopolitics': Icons.flag_outlined,
  'Arts & culture': Icons.palette_outlined,
  'Business': Icons.work_outline_rounded,
  'Society': Icons.groups_outlined,
  'Sport': Icons.sports_soccer_outlined,
  'Food': Icons.restaurant_outlined,
  'Space': Icons.rocket_launch_outlined,
  'Psychology': Icons.self_improvement_rounded,
  'Language': Icons.translate_rounded,
};

/// The style of [theme]. A theme without its own icon gets a generic one;
/// its colours depend only on its name, so they never change.
ThemeStyle themeStyle(String theme) {
  final palette =
      _palettes[theme.codeUnits.fold(0, (a, b) => a + b) % _palettes.length];
  return (
    icon: _icons[theme] ?? Icons.label_outline_rounded,
    background: palette.background,
    foreground: palette.foreground,
  );
}
