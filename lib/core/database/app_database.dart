import 'package:drift/drift.dart';

import 'converters.dart';
import 'tables/practice_sessions.dart';
import 'tables/session_feedbacks.dart';
import 'tables/session_recordings.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database, and the source of truth for
/// user data on the device.
///
/// Only data sources and repositories may use this class. Widgets get their
/// data from providers that expose domain objects.
@DriftDatabase(tables: [PracticeSessions, SessionFeedbacks, SessionRecordings])
class AppDatabase extends _$AppDatabase {
  /// Takes its connection as an argument so tests can pass an in-memory or
  /// temporary-file database. The app's own connection is in
  /// `database_connection.dart`.
  AppDatabase(super.connection);

  /// Every recorded version is frozen once the app has shipped: its tables
  /// are in `drift_schemas/app/drift_schema_v<N>.json` and must not change.
  ///
  /// - 1: practice_sessions, session_feedbacks and session_recordings
  ///   (carried over from the Nourish app, where they reached this shape).
  ///
  /// Any change to a table means adding 1 here, writing the step that takes
  /// existing databases to the new version in [migration], recording the new
  /// schema with `dart run drift_dev make-migrations` and testing the step
  /// with real rows. Do not raise this number for any other reason.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // No migration exists yet. A version this build cannot migrate (a file
      // written by a newer build) must fail here, leaving the file untouched.
      // Never drop or recreate tables to get past a migration: that destroys
      // user data.
      throw StateError(
        'No migration from schema version $from to $to. '
        'The database was left unchanged.',
      );
    },
    beforeOpen: (details) async {
      // SQLite does not enforce foreign keys unless asked to, per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
