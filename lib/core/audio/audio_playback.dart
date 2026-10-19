import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays a recording from a file on this device.
abstract interface class AudioPlayback {
  /// Plays the file at [path] from where it was paused, or from the start.
  Future<void> play(String path);
  Future<void> pause();
  Future<void> stop();

  /// Where playback is, as it moves.
  Stream<Duration> get position;

  /// Whether it is playing, each time that changes. Reaching the end is
  /// not playing.
  Stream<bool> get playing;

  Future<void> dispose();
}

/// [AudioPlayback] backed by the `audioplayers` package.
class PluginAudioPlayback implements AudioPlayback {
  final _player = AudioPlayer();
  String? _loaded;

  @override
  Future<void> play(String path) async {
    if (_loaded == path && _player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      _loaded = path;
      await _player.play(DeviceFileSource(path));
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<Duration> get position => _player.onPositionChanged;

  @override
  Stream<bool> get playing => _player.onPlayerStateChanged.map(
    (state) => state == PlayerState.playing,
  );

  @override
  Future<void> dispose() => _player.dispose();
}

/// A new player for each page that plays a recording. Tests replace it with
/// a fake.
final audioPlaybackProvider = Provider.autoDispose<AudioPlayback>((ref) {
  final player = PluginAudioPlayback();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});
