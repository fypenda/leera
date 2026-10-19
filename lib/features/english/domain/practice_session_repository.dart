import 'practice_session.dart';
import 'restitution_format.dart';
import 'session_feedback.dart';
import 'session_recording.dart';

/// Stores and retrieves English practice sessions.
///
/// This is the only way the rest of the app reaches session data. Nothing
/// here reveals how the data is stored.
abstract interface class PracticeSessionRepository {
  /// Starts a session on [topicId] in [format], researching from now.
  Future<PracticeSession> start({
    required String topicId,
    required RestitutionFormat format,
  });

  /// The session with this [id], or null if there is none.
  Future<PracticeSession?> getSession(String id);

  /// The session with this [id], or null once there is none. Emits again
  /// whenever it changes.
  Stream<PracticeSession?> watchSession(String id);

  /// Every session, the latest started first. Emits again whenever one
  /// changes.
  Stream<List<PracticeSession>> watchSessions();

  /// Replaces the notes of a session that is not completed.
  ///
  /// Throws [PracticeSessionNotFoundException] if there is no such session.
  Future<PracticeSession> saveNotes(String id, String notes);

  /// Draws the session's one other topic: see [PracticeSession.rerolledTo].
  Future<PracticeSession> reroll(
    String id, {
    required String topicId,
    required RestitutionFormat format,
  });

  /// Ends the research: see [PracticeSession.startPresenting].
  Future<PracticeSession> startPresenting(String id);

  /// Completes the session, keeping a written [presentation]: see
  /// [PracticeSession.completedWith].
  Future<PracticeSession> complete(String id, {String? presentation});

  /// Keeps the correction received for a completed session, replacing any
  /// earlier one.
  ///
  /// Throws [PracticeSessionNotFoundException] if there is no such session,
  /// and a [StateError] if it is not completed.
  Future<void> saveFeedback(String sessionId, SessionFeedback feedback);

  /// Every correction received, by session id. Emits again whenever one is
  /// saved.
  Stream<Map<String, SessionFeedback>> watchFeedbacks();

  /// Keeps the recording of a session's spoken presentation, in the file
  /// [fileName], replacing any earlier one. Returns the one replaced, whose
  /// file the caller deletes, or null.
  ///
  /// Throws [PracticeSessionNotFoundException] if there is no such session,
  /// a [StateError] if it is completed (what was sent stays as it was), and
  /// an [ArgumentError] if the values do not make a valid recording.
  Future<SessionRecording?> saveRecording(
    String sessionId, {
    required String fileName,
    required Duration duration,
  });

  /// Every recording, by session id. Emits again whenever one is saved.
  Stream<Map<String, SessionRecording>> watchRecordings();

  /// Keeps the text heard in the session's recording, replacing any earlier
  /// one. A sent presentation may still be transcribed: the recording is
  /// what was sent, the transcript only reads it.
  ///
  /// Throws a [StateError] if the session has no recording.
  Future<void> saveTranscript(String sessionId, String transcript);
}

class PracticeSessionNotFoundException implements Exception {
  const PracticeSessionNotFoundException(this.id);

  final String id;

  @override
  String toString() =>
      'PracticeSessionNotFoundException: no practice session with id $id';
}
