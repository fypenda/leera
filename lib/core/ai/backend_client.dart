import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_settings.dart';

/// Why a call to the backend failed, in terms the app can act on.
enum BackendFailure {
  /// The AI settings are not set up.
  notConfigured,

  /// No answer: the backend is down, the address is wrong, or there is no
  /// network.
  unreachable,

  /// The app token was refused.
  unauthorized,

  /// Too many requests in the last hour.
  rateLimited,

  /// The model could not be reached or answered with something unusable.
  aiUnavailable,

  /// The model declined to correct this.
  aiRefused,

  /// Anything else: an answer the app does not understand.
  unexpected,
}

class BackendException implements Exception {
  const BackendException(this.failure, [this.detail]);

  final BackendFailure failure;

  /// For the console only: never shown, never holding personal content.
  final String? detail;

  @override
  String toString() => 'BackendException(${failure.name}, $detail)';
}

/// Talks to the app's backend with the saved AI settings.
///
/// Plain HTTP and JSON over `dart:io`, with no package in between. Each call
/// reads the settings afresh, so a change applies at once.
class BackendClient {
  BackendClient(this._settings, {HttpClient Function()? newHttpClient})
    : _newHttpClient = newHttpClient ?? HttpClient.new;

  static const _timeout = Duration(seconds: 120);

  final Future<AiSettings?> Function() _settings;
  final HttpClient Function() _newHttpClient;

  /// Checks that the backend answers and accepts the token.
  Future<void> ping() async {
    await _send('GET', '/api/v1/ping');
  }

  /// Posts [body] as JSON to [path] and returns the JSON object answered.
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final answer = await _send('POST', path, body: body);
    if (answer is! Map<String, Object?>) {
      throw const BackendException(
        BackendFailure.unexpected,
        'The answer is not a JSON object.',
      );
    }
    return answer;
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final settings = await _settings();
    if (settings == null) {
      throw const BackendException(BackendFailure.notConfigured);
    }

    final client = _newHttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.openUrl(method, settings.resolve(path));
      request.headers
        ..set('X-App-Token', settings.appToken)
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join().timeout(_timeout);

      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        try {
          return text.isEmpty ? null : jsonDecode(text);
        } on FormatException {
          throw const BackendException(
            BackendFailure.unexpected,
            'The answer is not JSON.',
          );
        }
      }
      throw BackendException(_failureOf(status, text), 'HTTP $status');
    } on BackendException {
      rethrow;
    } on SocketException catch (e) {
      throw BackendException(BackendFailure.unreachable, e.message);
    } on HttpException catch (e) {
      throw BackendException(BackendFailure.unreachable, e.message);
    } on TimeoutException {
      throw const BackendException(BackendFailure.unreachable, 'Timed out.');
    } on HandshakeException catch (e) {
      throw BackendException(BackendFailure.unreachable, e.message);
    } finally {
      client.close(force: true);
    }
  }

  static BackendFailure _failureOf(int status, String text) {
    String? code;
    try {
      final json = jsonDecode(text);
      if (json is Map && json['code'] is String) code = json['code'] as String;
    } on FormatException {
      // Not one of the backend's own errors.
    }
    return switch ((status, code)) {
      (401, _) => BackendFailure.unauthorized,
      (429, _) => BackendFailure.rateLimited,
      (_, 'ai_refused') => BackendFailure.aiRefused,
      (_, 'ai_unavailable' || 'ai_invalid_response') =>
        BackendFailure.aiUnavailable,
      (502 || 503 || 504, _) => BackendFailure.unreachable,
      _ => BackendFailure.unexpected,
    };
  }
}

/// The client for the app's backend, with the saved settings.
final backendClientProvider = Provider<BackendClient>((ref) {
  final store = ref.watch(aiSettingsStoreProvider);
  return BackendClient(store.read);
});

/// What a person can do about a failure, in one sentence.
String describeBackendFailure(BackendFailure failure) => switch (failure) {
  BackendFailure.notConfigured =>
    'AI correction is not set up yet. Add your backend in the AI settings.',
  BackendFailure.unreachable =>
    'The backend could not be reached. Check that it is running and that '
        'the address is right.',
  BackendFailure.unauthorized =>
    'The backend refused the app token. Check it in the AI settings.',
  BackendFailure.rateLimited =>
    'Too many corrections in the last hour. Try again a little later.',
  BackendFailure.aiUnavailable =>
    'The correction service is not available right now. Try again.',
  BackendFailure.aiRefused => 'This presentation could not be corrected.',
  BackendFailure.unexpected =>
    'Something unexpected came back from the backend. Try again.',
};
