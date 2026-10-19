import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_connection.dart';

/// Where the database is stored. Tests override this with an in-memory
/// connection; the app uses the on-device file.
final databaseConnectionProvider = Provider<QueryExecutor>(
  (ref) => openDatabaseConnection(),
);

/// The app's database. Drift opens the connection on the first query, and
/// the database is closed when the enclosing ProviderScope is disposed.
///
/// Read this from data sources and repositories only, never from widgets.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(ref.watch(databaseConnectionProvider));
  ref.onDispose(database.close);
  return database;
});
