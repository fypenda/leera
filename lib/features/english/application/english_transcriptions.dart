import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/recording_files.dart';
import '../../../core/audio/transcriber.dart';
import '../data/practice_session_repository_provider.dart';
import '../domain/practice_session_repository.dart';

final transcriptionActionsProvider = Provider<TranscriptionActions>(
  (ref) => TranscriptionActions(
    ref.watch(practiceSessionRepositoryProvider),
    ref.watch(recordingFilesProvider),
    ref.watch(transcriberProvider),
  ),
);

/// Turning a session's recording into text, kept with the recording.
class TranscriptionActions {
  TranscriptionActions(this._repository, this._files, this._transcriber);

  final PracticeSessionRepository _repository;
  final RecordingFiles _files;
  final Transcriber _transcriber;

  /// Transcribes the recording of [sessionId] and keeps the text. Returns
  /// it: empty if nothing was heard.
  ///
  /// Throws a [TranscriptionException], and a [StateError] if the session
  /// has no recording.
  Future<String> transcribe(String sessionId) async {
    final recording = (await _repository.watchRecordings().first)[sessionId];
    if (recording == null) {
      throw StateError('The session $sessionId has no recording.');
    }
    if (!await _transcriber.requestPermission()) {
      throw const TranscriptionException(TranscriptionFailure.notAllowed);
    }
    final text = await _transcriber.transcribe(
      await _files.pathOf(recording.fileName),
    );
    await _repository.saveTranscript(sessionId, text);
    return text;
  }
}
