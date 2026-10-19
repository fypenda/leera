import 'package:flutter/painting.dart';

/// Palette of the "Growth App" design (Claude Design canvas, October 2026).
///
/// Every pairing used for text was checked against WCAG AA (4.5:1): text and
/// textMuted on background and surface, primary on surface, background and
/// primarySoft, ink on highlight and accent, accentStrong on accentSoft,
/// coralStrong on coralSoft, surface on ink.
abstract final class AppColors {
  static const background = Color(0xFFFBF0E7);
  static const sidebar = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);

  /// Tracks of progress bars, empty days, quiet chips.
  static const surfaceMuted = Color(0xFFF3E4D8);
  static const border = Color(0xFFEFE0D3);

  /// Links, selected navigation, emphasis in text and icons.
  static const primary = Color(0xFF1C6F7B);
  static const primarySoft = Color(0xFFDDF3F6);

  /// The bright teal of hero cards and progress. Not for text: put [ink] on it.
  static const highlight = Color(0xFF5FC4D2);

  /// A paler [highlight], for quiet elements drawn on top of it.
  static const highlightSoft = Color(0xFFA9DEE6);

  static const accent = Color(0xFFF09669);
  static const accentSoft = Color(0xFFFCE3D6);

  /// Accent dark enough to be read as text, on [accentSoft] or lighter.
  static const accentStrong = Color(0xFF8A3F1E);

  /// For what needs attention: overdue, recording, a correction.
  static const coral = Color(0xFFD96266);
  static const coralSoft = Color(0xFFF8DCDD);
  static const coralStrong = Color(0xFFA3373C);

  static const text = Color(0xFF24323A);
  static const textMuted = Color(0xFF5E6A70);

  /// Main call-to-action buttons: the darkest colour, under [surface] text.
  static const ink = text;
}
