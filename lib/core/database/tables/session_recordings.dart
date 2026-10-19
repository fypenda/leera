import 'package:drift/drift.dart';

import '../converters.dart';
import 'practice_sessions.dart';

/// The recording of a spoken presentation: one per English practice
/// session at most. Deleting the session deletes the row (the audio file
/// itself is managed by the app).
///
/// `file_name` is the name of the audio file in the app's recordings
/// folder, never a full path: the folder can move between app updates.
/// `duration_ms` is the recording's length in milliseconds. `transcript` is
/// the text heard in it, once transcribed (empty if nothing was heard); a
/// new take starts without one.
@DataClassName('SessionRecordingRow')
class SessionRecordings extends Table {
  TextColumn get sessionId =>
      text().references(PracticeSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  IntColumn get durationMs => integer()();
  IntColumn get recordedAt => integer().map(const UtcInstantConverter())();
  TextColumn get transcript => text().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId};

  @override
  List<String> get customConstraints => [
    "CHECK (length(trim(file_name)) > 0 AND instr(file_name, '/') = 0)",
    'CHECK (duration_ms > 0)',
  ];
}
