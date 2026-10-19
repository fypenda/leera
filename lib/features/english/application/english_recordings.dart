import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/recording_files.dart';
import '../../../core/time/clock.dart';
import '../data/practice_session_repository_provider.dart';
import '../domain/practice_session_repository.dart';
import '../domain/session_recording.dart';

/// Every recording, by session id. Emits again whenever one is saved.
final recordingsProvider = StreamProvider<Map<String, SessionRecording>>(
  (ref) => ref.watch(practiceSessionRepositoryProvider).watchRecordings(),
  retry: (retryCount, error) => null,
);

final recordingActionsProvider = Provider<RecordingActions>(
  (ref) => RecordingActions(
    ref.watch(practiceSessionRepositoryProvider),
    ref.watch(recordingFilesProvider),
    ref.watch(clockProvider),
  ),
);

/// A file to record into, by its name and its full path.
typedef RecordingTarget = ({String fileName, String path});

/// Where recordings go, and keeping or discarding them.
class RecordingActions {
  RecordingActions(this._repository, this._files, this._clock);

  final PracticeSessionRepository _repository;
  final RecordingFiles _files;
  final Clock _clock;

  /// A new file for a recording of [sessionId]. Each take gets its own, so
  /// an earlier recording is only replaced once a new one is kept.
  Future<RecordingTarget> newTarget(String sessionId) async {
    final fileName =
        '$sessionId-${_clock().toUtc().millisecondsSinceEpoch}.m4a';
    return (fileName: fileName, path: await _files.pathOf(fileName));
  }

  /// Keeps the take in [fileName] as the session's recording, and deletes
  /// the file of the one it replaces.
  Future<void> keep(
    String sessionId, {
    required String fileName,
    required Duration duration,
  }) async {
    final previous = await _repository.saveRecording(
      sessionId,
      fileName: fileName,
      duration: duration,
    );
    if (previous != null && previous.fileName != fileName) {
      await _files.delete(previous.fileName);
    }
  }

  /// The full path of a kept recording.
  Future<String> pathOf(SessionRecording recording) =>
      _files.pathOf(recording.fileName);
}
