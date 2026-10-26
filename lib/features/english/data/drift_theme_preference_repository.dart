import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/theme_preferences.dart';

/// [ThemePreferenceRepository] backed by the local SQLite database.
class DriftThemePreferenceRepository implements ThemePreferenceRepository {
  DriftThemePreferenceRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<Set<String>> watchThemes() => _db
      .select(_db.preferredThemes)
      .watch()
      .map((rows) => {for (final row in rows) row.theme});

  @override
  Future<void> setThemes(Set<String> themes) => _db.transaction(() async {
    await _db.delete(_db.preferredThemes).go();
    await _db.batch(
      (batch) => batch.insertAll(_db.preferredThemes, [
        for (final theme in themes)
          if (theme.trim().isNotEmpty)
            PreferredThemesCompanion.insert(theme: theme.trim()),
      ]),
    );
  });
}
