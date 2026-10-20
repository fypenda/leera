import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/quota.dart';
import '../auth/session.dart';

/// The backend's address, chosen when the app is built:
/// `flutter run --dart-define=LEERA_API_URL=https://api.example.com`.
const backendUrl = String.fromEnvironment(
  'LEERA_API_URL',
  defaultValue: 'http://localhost:8080',
);

/// Why a call to the backend failed, in terms the app can act on.
enum BackendFailure {
  /// Not signed in, or the session is no longer valid.
  signedOut,

  /// No answer: the backend is down, or there is no network.
  unreachable,

  /// Sign in with Apple could not be verified.
  invalidIdentity,

  /// Every correction of the quota is used for now.
  quotaExceeded,

  /// Too many requests to the backend in the last hour.
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

/// What signing in gives back.
typedef SignedIn = ({Session session, Quota quota});

/// Talks to the app's backend.
///
/// Plain HTTP and JSON over `dart:io`, with no package in between. Each call
/// reads the session afresh, so signing in or out applies at once. When the
/// backend refuses a session, [onSignedOut] is called, so the app can forget
/// it and ask the person to sign in again.
class BackendClient {
  BackendClient(
    this._baseUrl,
    this._session, {
    void Function()? onSignedOut,
    HttpClient Function()? newHttpClient,
  }) : _onSignedOut = onSignedOut,
       _newHttpClient = newHttpClient ?? HttpClient.new;

  static const _timeout = Duration(seconds: 120);

  final Uri _baseUrl;
  final Future<Session?> Function() _session;
  final void Function()? _onSignedOut;
  final HttpClient Function() _newHttpClient;

  /// Opens a session with an identity token from Sign in with Apple and the
  /// raw nonce whose hash it carries.
  Future<SignedIn> signInWithApple({
    required String identityToken,
    required String nonce,
  }) async {
    final answer = await _object(
      'POST',
      '/api/v1/auth/apple',
      body: {'identityToken': identityToken, 'nonce': nonce},
      signedIn: false,
    );
    return _signedIn(answer);
  }

  /// Opens a session without Apple, as the development account [name].
  ///
  /// Only a backend started with `LEERA_DEV_SIGN_IN=true` accepts it; the
  /// app offers it in debug builds only.
  Future<SignedIn> devSignIn(String name) async {
    final answer = await _object(
      'POST',
      '/api/v1/auth/dev',
      body: {'name': name},
      signedIn: false,
    );
    return _signedIn(answer);
  }

  static SignedIn _signedIn(Map<String, Object?> answer) {
    try {
      final expiresAt = DateTime.tryParse('${answer['expiresAt']}');
      final token = answer['accessToken'];
      if (token is! String || expiresAt == null) {
        throw const FormatException('The session is incomplete.');
      }
      return (
        session: Session(accessToken: token, expiresAt: expiresAt),
        quota: Quota.fromJson(answer['quota']),
      );
    } on FormatException catch (e) {
      throw BackendException(BackendFailure.unexpected, e.message);
    } on ArgumentError {
      throw const BackendException(
        BackendFailure.unexpected,
        'The session is blank.',
      );
    }
  }

  /// Where the account stands with its quota.
  Future<Quota> quota() async {
    final answer = await _object('GET', '/api/v1/me');
    try {
      return Quota.fromJson(answer['quota']);
    } on FormatException catch (e) {
      throw BackendException(BackendFailure.unexpected, e.message);
    }
  }

  /// Deletes the account and everything the backend holds about it.
  Future<void> deleteAccount() async {
    await _send('DELETE', '/api/v1/account');
  }

  /// Posts [body] as JSON to [path] and returns the JSON object answered.
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) => _object('POST', path, body: body);

  Future<Map<String, Object?>> _object(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool signedIn = true,
  }) async {
    final answer = await _send(method, path, body: body, signedIn: signedIn);
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
    bool signedIn = true,
  }) async {
    Session? session;
    if (signedIn) {
      session = await _session();
      if (session == null) {
        throw const BackendException(BackendFailure.signedOut);
      }
    }

    final client = _newHttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.openUrl(method, _baseUrl.resolve(path));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (session != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${session.accessToken}',
        );
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(_timeout);
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);

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
      final failure = _failureOf(status, text);
      if (failure == BackendFailure.signedOut && signedIn) {
        _onSignedOut?.call();
      }
      throw BackendException(failure, 'HTTP $status');
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
      (401, 'invalid_identity') => BackendFailure.invalidIdentity,
      (401, _) => BackendFailure.signedOut,
      (429, 'quota_exceeded') => BackendFailure.quotaExceeded,
      (429, _) => BackendFailure.rateLimited,
      (_, 'ai_refused') => BackendFailure.aiRefused,
      (_, 'ai_unavailable' || 'ai_invalid_response') =>
        BackendFailure.aiUnavailable,
      (502 || 503 || 504, _) => BackendFailure.unreachable,
      _ => BackendFailure.unexpected,
    };
  }
}

/// The backend's address. Tests may replace it.
final backendUrlProvider = Provider<Uri>((ref) => Uri.parse(backendUrl));

/// The client for the app's backend, with the saved session. A session the
/// backend refuses is forgotten, which sends the person back to sign in.
final backendClientProvider = Provider<BackendClient>((ref) {
  final store = ref.watch(sessionStoreProvider);
  return BackendClient(
    ref.watch(backendUrlProvider),
    store.read,
    onSignedOut: () async {
      await store.clear();
      ref.invalidate(sessionProvider);
    },
  );
});

/// What a person can do about a failure, in one sentence.
String describeBackendFailure(BackendFailure failure) => switch (failure) {
  BackendFailure.signedOut => 'Your session has ended. Sign in again.',
  BackendFailure.unreachable =>
    'Leera could not be reached. Check your connection and try again.',
  BackendFailure.invalidIdentity =>
    'Sign in with Apple could not be verified. Try again.',
  BackendFailure.quotaExceeded =>
    'You have used all your corrections for now. Your presentation is '
        'saved: it can be corrected when your quota starts again.',
  BackendFailure.rateLimited =>
    'Leera is very busy right now. Try again a little later.',
  BackendFailure.aiUnavailable =>
    'The correction service is not available right now. Try again.',
  BackendFailure.aiRefused => 'This presentation could not be corrected.',
  BackendFailure.unexpected =>
    'Something unexpected came back from Leera. Try again.',
};
