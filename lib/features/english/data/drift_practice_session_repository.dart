import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/common/id_generator.dart';
import '../../../core/database/app_database.dart';
import '../../../core/time/clock.dart';
import '../domain/feedback_codec.dart';
import '../domain/practice_session.dart';
import '../domain/practice_session_repository.dart';
import '../domain/restitution_format.dart';
import '../domain/session_feedback.dart';
import '../domain/session_recording.dart';

/// [PracticeSessionRepository] backed by the local SQLite database.
///
/// Every write builds the domain object first, so the domain rules are
/// checked before anything reaches the database. Every read rebuilds it, so
/// a row that breaks those rules fails loudly instead of being passed on.
class DriftPracticeSessionRepository implements PracticeSessionRepository {
  DriftPracticeSessionRepository(
    this._db, {
    required this._clock,
    required this._newId,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  DateTime _now() => _clock().toUtc();

  @override
  Future<PracticeSession> start({
    required String topicId,
    required RestitutionFormat format,
  }) async {
    final now = _now();
    final session = PracticeSession(
      id: _newId(),
      topicId: topicId,
      format: format,
      status: PracticeSessionStatus.researching,
      startedAt: now,
      updatedAt: now,
    );
    await _db.into(_db.practiceSessions).insert(_toRow(session));
    return session;
  }

  @override
  Future<PracticeSession?> getSession(String id) async {
    final row = await _byId(id).getSingleOrNull();
    return row == null ? null : practiceSessionFromRow(row);
  }

  @override
  Stream<PracticeSession?> watchSession(String id) => _byId(
    id,
  ).watchSingleOrNull().map((row) => row == null ? null : practiceSessionFromRow(row));

  @override
  Stream<List<PracticeSession>> watchSessions() {
    final query = _db.select(_db.practiceSessions)
      ..orderBy([
        (s) => OrderingTerm.desc(s.startedAt),
        (s) => OrderingTerm.asc(s.id),
      ]);
    return query.watch().map((rows) => rows.map(practiceSessionFromRow).toList());
  }

  @override
  Future<PracticeSession> saveNotes(String id, String notes) =>
      _change(id, (session) => session.withNotes(notes, _now()));

  @override
  Future<PracticeSession> reroll(
    String id, {
    required String topicId,
    required RestitutionFormat format,
  }) => _change(
    id,
    (session) => session.rerolledTo(topicId, format, _now()),
  );

  @override
  Future<PracticeSession> startPresenting(String id) =>
      _change(id, (session) => session.startPresenting(_now()));

  @override
  Future<PracticeSession> complete(String id, {String? presentation}) =>
      _change(id, (session) => session.completedWith(presentation, _now()));

  @override
  Future<void> saveFeedback(String sessionId, SessionFeedback feedback) {
    return _db.transaction(() async {
      final row = await _byId(sessionId).getSingleOrNull();
      if (row == null) throw PracticeSessionNotFoundException(sessionId);
      if (!practiceSessionFromRow(row).isCompleted) {
        throw StateError('Only a completed session has a correction.');
      }
      await _db
          .into(_db.sessionFeedbacks)
          .insertOnConflictUpdate(
            SessionFeedbackRow(
              sessionId: sessionId,
              payload: jsonEncode(encodeFeedback(feedback)),
              receivedAt: _now(),
            ),
          );
    });
  }

  @override
  Stream<Map<String, SessionFeedback>> watchFeedbacks() => _db
      .select(_db.sessionFeedbacks)
      .watch()
      .map(
        (rows) => {
          // A payload that cannot be read is corrupt: it fails loudly.
          for (final row in rows)
            row.sessionId: decodeFeedback(jsonDecode(row.payload)),
        },
      );

  @override
  Future<SessionRecording?> saveRecording(
    String sessionId, {
    required String fileName,
    required Duration duration,
  }) async {
    final recording = SessionRecording(
      sessionId: sessionId,
      fileName: fileName,
      duration: duration,
      recordedAt: _now(),
    );
    return _db.transaction(() async {
      final row = await _byId(sessionId).getSingleOrNull();
      if (row == null) throw PracticeSessionNotFoundException(sessionId);
      if (practiceSessionFromRow(row).isCompleted) {
        throw StateError('A sent presentation is not recorded again.');
      }
      final previous = await (_db.select(
        _db.sessionRecordings,
      )..where((r) => r.sessionId.equals(sessionId))).getSingleOrNull();
      await _db
          .into(_db.sessionRecordings)
          .insertOnConflictUpdate(
            SessionRecordingsCompanion.insert(
              sessionId: sessionId,
              fileName: recording.fileName,
              durationMs: recording.duration.inMilliseconds,
              recordedAt: recording.recordedAt,
              // A new take has not been heard yet: an explicit null, so the
              // earlier take's transcript is cleared, not kept.
              transcript: const Value(null),
            ),
          );
      return previous == null ? null : sessionRecordingFromRow(previous);
    });
  }

  @override
  Future<void> saveTranscript(String sessionId, String transcript) async {
    final updated =
        await (_db.update(
          _db.sessionRecordings,
        )..where((r) => r.sessionId.equals(sessionId))).write(
          SessionRecordingsCompanion(transcript: Value(transcript)),
        );
    if (updated == 0) {
      throw StateError('The session $sessionId has no recording.');
    }
  }

  @override
  Stream<Map<String, SessionRecording>> watchRecordings() => _db
      .select(_db.sessionRecordings)
      .watch()
      .map(
        (rows) => {
          for (final row in rows) row.sessionId: sessionRecordingFromRow(row),
        },
      );

  Future<PracticeSession> _change(
    String id,
    PracticeSession Function(PracticeSession) change,
  ) {
    return _db.transaction(() async {
      final row = await _byId(id).getSingleOrNull();
      if (row == null) throw PracticeSessionNotFoundException(id);

      final before = practiceSessionFromRow(row);
      final after = change(before);
      if (!identical(after, before)) {
        await _db.update(_db.practiceSessions).replace(_toRow(after));
      }
      return after;
    });
  }

  SimpleSelectStatement<$PracticeSessionsTable, PracticeSessionRow> _byId(
    String id,
  ) => _db.select(_db.practiceSessions)..where((s) => s.id.equals(id));
}

/// Rebuilds the domain object from its row, so that a row breaking a rule
/// fails loudly. Public so that a restored backup can be checked the same
/// way (`app/backup/`).
PracticeSession practiceSessionFromRow(PracticeSessionRow row) => PracticeSession(
  id: row.id,
  topicId: row.topicId,
  format: RestitutionFormat.values.byName(row.format),
  status: PracticeSessionStatus.values.byName(row.status),
  notes: row.notes,
  presentation: row.presentation,
  rerolled: row.rerolled,
  startedAt: row.startedAt,
  updatedAt: row.updatedAt,
  completedAt: row.completedAt,
);

PracticeSessionRow _toRow(PracticeSession session) => PracticeSessionRow(
  id: session.id,
  topicId: session.topicId,
  format: session.format.name,
  status: session.status.name,
  notes: session.notes,
  presentation: session.presentation,
  rerolled: session.rerolled,
  startedAt: session.startedAt,
  updatedAt: session.updatedAt,
  completedAt: session.completedAt,
);

/// Rebuilds the domain object from its row, so that a row breaking a rule
/// fails loudly. Public so that a restored backup can be checked the same
/// way (`app/backup/`).
SessionRecording sessionRecordingFromRow(SessionRecordingRow row) => SessionRecording(
  sessionId: row.sessionId,
  fileName: row.fileName,
  duration: Duration(milliseconds: row.durationMs),
  recordedAt: row.recordedAt,
  transcript: row.transcript,
);
