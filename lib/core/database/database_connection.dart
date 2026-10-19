import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// The name of the app's database; its file is `vocara.sqlite`.
const appDatabaseName = 'vocara';

/// Opens an on-device database file, by default the app's own.
///
/// It lives in Application Support rather than Documents: the file is app
/// data, not something the user should see or edit in the Files app.
///
/// The app never passes [name]. It exists so that a test can go through this
/// exact code, on a device, without touching the app's real database.
QueryExecutor openDatabaseConnection({String name = appDatabaseName}) {
  return driftDatabase(
    name: name,
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
  );
}
