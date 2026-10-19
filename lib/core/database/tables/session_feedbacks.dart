import 'package:drift/drift.dart';

import '../converters.dart';
import 'practice_sessions.dart';

/// The correction received for a practice session, at most one per session.
/// Deleting the session deletes it.
///
/// `payload` is the correction as the backend sent it, as JSON text: its
/// shape is defined by `feedback_codec.dart` in the English feature, and is a
/// contract with stored data. `received_at` is when it reached the device.
@DataClassName('SessionFeedbackRow')
class SessionFeedbacks extends Table {
  TextColumn get sessionId =>
      text().references(PracticeSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get payload => text()();
  IntColumn get receivedAt => integer().map(const UtcInstantConverter())();

  @override
  Set<Column> get primaryKey => {sessionId};

  @override
  List<String> get customConstraints => [
    "CHECK (length(payload) > 2)",
  ];
}
