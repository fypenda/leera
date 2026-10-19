import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// How a recording in progress is going: how long it has run, not counting
/// pauses, and how loud it is right now, from 0 (silence) to 1.
typedef RecordingProgress = ({Duration elapsed, double level});

/// Records the microphone to a file, on this device only.
abstract interface class VoiceRecorder {
  /// Asks for the microphone, which shows the system's prompt the first
  /// time. Returns whether it may be used.
  Future<bool> requestPermission();

  /// Starts recording to the file at [path], replacing it if it exists.
  Future<void> start(String path);

  Future<void> pause();
  Future<void> resume();

  /// Stops and keeps the file. Returns how long the recording is.
  Future<Duration> stop();

  /// Stops and deletes the file.
  Future<void> cancel();

  /// Progress while recording, a few times a second.
  Stream<RecordingProgress> get progress;

  Future<void> dispose();
}

/// [VoiceRecorder] backed by the `record` package, in AAC (`.m4a`).
class PluginVoiceRecorder implements VoiceRecorder {
  PluginVoiceRecorder() : _recorder = AudioRecorder();

  static const _tick = Duration(milliseconds: 100);

  final AudioRecorder _recorder;
  final _elapsed = Stopwatch();
  String? _path;

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) async {
    _path = path;
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
      path: path,
    );
    _elapsed
      ..reset()
      ..start();
  }

  @override
  Future<void> pause() async {
    await _recorder.pause();
    _elapsed.stop();
  }

  @override
  Future<void> resume() async {
    await _recorder.resume();
    _elapsed.start();
  }

  @override
  Future<Duration> stop() async {
    await _recorder.stop();
    _elapsed.stop();
    return _elapsed.elapsed;
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    _elapsed
      ..stop()
      ..reset();
    final path = _path;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Stream<RecordingProgress> get progress =>
      _recorder.onAmplitudeChanged(_tick).map(
        (amplitude) => (
          elapsed: _elapsed.elapsed,
          // dBFS, from about -60 (silence) to 0 (as loud as it gets).
          level: ((amplitude.current + 60) / 60).clamp(0.0, 1.0).toDouble(),
        ),
      );

  @override
  Future<void> dispose() => _recorder.dispose();
}

/// A new recorder for each recording page. Tests replace it with a fake.
final voiceRecorderProvider = Provider.autoDispose<VoiceRecorder>((ref) {
  final recorder = PluginVoiceRecorder();
  ref.onDispose(() => unawaited(recorder.dispose()));
  return recorder;
});

/// [level], softened so that quiet speech still shows on a waveform.
double displayLevel(double level) => math.sqrt(level.clamp(0.0, 1.0));
