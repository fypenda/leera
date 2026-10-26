/// Where the themes the daily topic is drawn from are kept.
abstract interface class ThemePreferenceRepository {
  /// The chosen themes, updated as they change. Empty: every theme.
  Stream<Set<String>> watchThemes();

  /// Replaces the chosen themes with [themes].
  Future<void> setThemes(Set<String> themes);
}
