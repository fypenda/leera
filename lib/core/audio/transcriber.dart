import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_name.dart';

/// Why a recording could not be turned into text.
enum TranscriptionFailure {
  /// Speech recognition is not allowed for the app.
  notAllowed,

  /// Speech recognition is not available right now (no network for a device
  /// that cannot recognise on its own, or English is not installed).
  unavailable,

  /// Anything else.
  failed,
}

class TranscriptionException implements Exception {
  const TranscriptionException(this.failure, [this.detail]);

  final TranscriptionFailure failure;
  final String? detail;

  @override
  String toString() => 'TranscriptionException(${failure.name}, $detail)';
}

/// Turns a recording into text.
abstract interface class Transcriber {
  /// Asks for speech recognition, which shows the system's prompt the first
  /// time. Returns whether it is allowed.
  Future<bool> requestPermission();

  /// The text heard in the audio file at [path], in the language of
  /// [locale] (such as `en-US` or `fr-FR`), or an empty text if nothing was
  /// heard. Throws a [TranscriptionException].
  Future<String> transcribe(String path, {String locale = 'en-US'});
}

/// [Transcriber] backed by Apple's speech recognition, through the app's
/// own channel (`SpeechTranscriber` in `ios/Runner/AppDelegate.swift`). It
/// runs on the device whenever the device can.
class SpeechTranscriber implements Transcriber {
  static const _channel = MethodChannel('app/transcription');

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<String> transcribe(String path, {String locale = 'en-US'}) async {
    try {
      final text = await _channel.invokeMethod<String>('transcribe', {
        'path': path,
        'locale': locale,
      });
      return (text ?? '').trim();
    } on PlatformException catch (e) {
      throw TranscriptionException(switch (e.code) {
        'not_authorized' => TranscriptionFailure.notAllowed,
        'unavailable' => TranscriptionFailure.unavailable,
        _ => TranscriptionFailure.failed,
      }, e.message);
    } on MissingPluginException catch (e) {
      throw TranscriptionException(TranscriptionFailure.unavailable, e.message);
    }
  }
}

/// How recordings become text. Tests replace it with a fake.
final transcriberProvider = Provider<Transcriber>((ref) => SpeechTranscriber());

/// What the person can do about a failure, in one sentence.
String describeTranscriptionFailure(TranscriptionFailure failure) =>
    switch (failure) {
      TranscriptionFailure.notAllowed =>
        '$appName may not use speech recognition. Allow it in the Settings '
            'app, under $appName › Speech Recognition, then try again.',
      TranscriptionFailure.unavailable =>
        'Speech recognition is not available right now. Check your '
            'connection and that the language is set up on this device, then '
            'try again.',
      TranscriptionFailure.failed =>
        'Your recording could not be turned into text. Try again.',
    };
