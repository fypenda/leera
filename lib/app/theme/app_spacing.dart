abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 36;
}

/// Corner radii. The design is soft and round: fields and chips use [md],
/// cards [lg], large hero cards [xl], buttons and pills are fully rounded.
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Large enough to make any button or chip a pill.
  static const double pill = 999;
}
