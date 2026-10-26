import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

/// Small settings kept on this device, by key.
abstract interface class SettingsRepository {
  Stream<String?> watch(String key);

  /// Stores [value] under [key], replacing what was there.
  Future<void> write(String key, String value);
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<String?> watch(String key) => (_db.select(
    _db.appSettings,
  )..where((row) => row.key.equals(key))).watchSingleOrNull().map((row) => row?.value);

  @override
  Future<void> write(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// The keys of the settings, in one place.
abstract final class SettingKeys {
  /// "done" once the welcome has been gone through.
  static const welcome = 'welcome';

  /// The level the person gave in the welcome, one of the CEFR levels.
  static const selfAssessedLevel = 'self_assessed_level';
}

/// Whether the welcome has been gone through on this device.
final welcomeDoneProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.welcome)
      .map((value) => value == 'done'),
);

/// The level the person gave in the welcome, or null.
final selfAssessedLevelProvider = StreamProvider<String?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.selfAssessedLevel),
);
