import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Rounded, heavy display face for titles.
const displayFontFamily = 'BricolageGrotesque';

/// Friendly sans for everything else.
const bodyFontFamily = 'Nunito';

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary)
      .copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.accent,
        onSecondary: AppColors.text,
        surface: AppColors.background,
        onSurface: AppColors.text,
        onSurfaceVariant: AppColors.textMuted,
        outlineVariant: AppColors.border,
        error: AppColors.coralStrong,
      );

  const textTheme = TextTheme(
    // Page title
    displaySmall: TextStyle(
      fontFamily: displayFontFamily,
      fontSize: 38,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -0.7,
      color: AppColors.text,
    ),
    // Card title
    headlineSmall: TextStyle(
      fontFamily: displayFontFamily,
      fontSize: 21,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.2,
      color: AppColors.text,
    ),
    // Wordmark
    titleLarge: TextStyle(
      fontFamily: displayFontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: AppColors.text,
    ),
    // Small headings inside cards
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w800,
      color: AppColors.text,
    ),
    bodyLarge: TextStyle(
      letterSpacing: 0,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
    ),
    bodyMedium: TextStyle(
      letterSpacing: 0,
      fontSize: 14,
      height: 1.5,
      color: AppColors.textMuted,
    ),
    // Names written in Arabic. Neither bundled font has Arabic glyphs, so
    // these are drawn with the system's Arabic font.
    titleSmall: TextStyle(
      letterSpacing: 0,
      fontSize: 19,
      fontWeight: FontWeight.w400,
      color: AppColors.text,
    ),
    // Breadcrumb, date, footer
    bodySmall: TextStyle(
      letterSpacing: 0,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textMuted,
    ),
    // Navigation labels, table cells
    labelLarge: TextStyle(
      letterSpacing: 0,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    // Pills
    labelMedium: TextStyle(
      letterSpacing: 0,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppColors.textMuted,
    ),
    // Eyebrows and table column headings, in capitals
    labelSmall: TextStyle(
      letterSpacing: 1.3,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: AppColors.textMuted,
    ),
  );

  const buttonText = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
  const pill = StadiumBorder();

  return ThemeData(
    // A swipe from the left edge goes back, on every page that can go back,
    // as iOS users expect (and on a Mac too).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: bodyFontFamily,
    textTheme: textTheme,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primarySoft,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: bodyFontFamily,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w700,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.highlight,
      linearTrackColor: AppColors.surfaceMuted,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.primarySoft,
      headerForegroundColor: AppColors.text,
      todayBorder: const BorderSide(color: AppColors.accent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      actionTextColor: AppColors.highlight,
      contentTextStyle: const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.surface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        textStyle: buttonText,
        shape: pill,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg + 2,
        ),
        textStyle: buttonText,
        shape: pill,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.surfaceMuted, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        textStyle: buttonText,
        shape: pill,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.surfaceMuted),
      labelStyle: textTheme.labelLarge,
      shape: const StadiumBorder(),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.highlight
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.ink),
      side: const BorderSide(color: AppColors.textMuted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
    ),
  );
}
