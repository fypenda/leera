/// The recording of a session's spoken presentation, kept on the device.
///
/// A recording that exists is valid: the constructor rejects inconsistent
/// state with an [ArgumentError].
class SessionRecording {
  SessionRecording({
    required this.sessionId,
    required this.fileName,
    required this.duration,
    required this.recordedAt,
    this.transcript,
  }) {
    if (fileName.trim().isEmpty || fileName.contains('/')) {
      throw ArgumentError.value(fileName, 'fileName', 'A file name, no path.');
    }
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive.');
    }
    if (!recordedAt.isUtc) {
      throw ArgumentError.value(recordedAt, 'recordedAt', 'Must be UTC.');
    }
  }

  final String sessionId;

  /// The audio file's name in the app's recordings folder.
  final String fileName;
  final Duration duration;
  final DateTime recordedAt;

  /// The text heard in the recording, once transcribed; empty if nothing
  /// was heard, null until then.
  final String? transcript;
}

/// "1:24", "0:07".
String formatRecordingLength(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
