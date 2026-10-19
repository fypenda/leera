import 'dart:async';
import 'dart:typed_data';

import 'package:vocara/core/audio/audio_playback.dart';
import 'package:vocara/core/audio/recording_files.dart';
import 'package:vocara/core/audio/transcriber.dart';
import 'package:vocara/core/audio/voice_recorder.dart';

/// A microphone that records nothing: the test says how loud and how long.
class FakeVoiceRecorder implements VoiceRecorder {
  FakeVoiceRecorder({this.allowed = true});

  /// What the system answers when asked for the microphone.
  bool allowed;
  int permissionRequests = 0;

  /// The path of each take started, in order.
  final started = <String>[];
  var paused = false;
  var cancelled = 0;
  Duration _elapsed = Duration.zero;
  final _progress = StreamController<RecordingProgress>.broadcast();

  /// As if the take had run to [elapsed] at [level].
  void emit(Duration elapsed, {double level = 0.5}) {
    _elapsed = elapsed;
    _progress.add((elapsed: elapsed, level: level));
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<void> start(String path) async {
    started.add(path);
    _elapsed = Duration.zero;
    paused = false;
  }

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume() async => paused = false;

  @override
  Future<Duration> stop() async => _elapsed;

  @override
  Future<void> cancel() async => cancelled++;

  @override
  Stream<RecordingProgress> get progress => _progress.stream;

  @override
  Future<void> dispose() async {}
}

/// A player that plays nothing: the test says where it is.
class FakeAudioPlayback implements AudioPlayback {
  final played = <String>[];
  var pauses = 0;
  final _position = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();

  void moveTo(Duration position) => _position.add(position);

  @override
  Future<void> play(String path) async {
    played.add(path);
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    _playing.add(false);
  }

  @override
  Future<void> stop() async => _playing.add(false);

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> dispose() async {}
}

/// A recordings folder in memory: nothing touches the disk.
class FakeRecordingFiles implements RecordingFiles {
  final deleted = <String>[];

  /// The audio kept, by file name.
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String fileName) async => files[fileName];

  @override
  Future<void> write(String fileName, Uint8List bytes) async =>
      files[fileName] = bytes;

  @override
  Future<String> pathOf(String fileName) async => '/recordings/$fileName';

  @override
  Future<void> delete(String fileName) async {
    deleted.add(fileName);
    files.remove(fileName);
  }
}

/// Speech recognition that hears what the test says it hears.
class FakeTranscriber implements Transcriber {
  FakeTranscriber({
    this.allowed = true,
    this.text = 'So the canal it opened in 1869 and it change everything.',
    this.failure,
  });

  bool allowed;
  String text;
  TranscriptionFailure? failure;

  /// The path of each file transcribed, in order.
  final transcribed = <String>[];

  /// The language asked for each one, in the same order.
  final locales = <String>[];

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<String> transcribe(String path, {String locale = 'en-US'}) async {
    transcribed.add(path);
    locales.add(locale);
    if (failure case final failure?) throw TranscriptionException(failure);
    return text;
  }
}
