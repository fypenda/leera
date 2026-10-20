import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/ai/backend_client.dart';
import 'package:leera/core/auth/apple_sign_in.dart';
import 'package:leera/core/auth/quota.dart';
import 'package:leera/core/auth/session.dart';

/// A local server that answers every request with [status] and [body], and
/// remembers the last request.
class _Backend {
  late HttpServer server;
  int status = 200;
  String body = '{}';
  String? authorization;
  String? method;
  String? path;
  Object? received;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      method = request.method;
      path = request.uri.path;
      final text = await utf8.decodeStream(request);
      received = text.isEmpty ? null : jsonDecode(text);
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(body);
      await request.response.close();
    });
  }

  Uri get url => Uri.parse('http://${server.address.host}:${server.port}');
}

final _session = Session(
  accessToken: 'session-token',
  expiresAt: DateTime.utc(2026, 11, 18),
);

const _quotaJson =
    '{"plan":"free","used":0,"limit":1,"resetsAt":"2026-10-26T00:00:00Z"}';

Matcher _fails(BackendFailure failure) => throwsA(
  isA<BackendException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  late _Backend backend;
  late BackendClient client;
  late int signedOut;

  setUp(() async {
    backend = _Backend();
    await backend.start();
    signedOut = 0;
    client = BackendClient(
      backend.url,
      () async => _session,
      onSignedOut: () => signedOut++,
    );
  });
  tearDown(() => backend.server.close(force: true));

  test('signing in sends the identity token and the raw nonce', () async {
    backend.body =
        '{"accessToken":"new-token","expiresAt":"2026-11-18T10:00:00Z",'
        '"quota":$_quotaJson}';
    final signedOutClient = BackendClient(backend.url, () async => null);

    final signedIn = await signedOutClient.signInWithApple(
      identityToken: 'apple-token',
      nonce: 'raw-nonce',
    );

    expect(backend.method, 'POST');
    expect(backend.path, '/api/v1/auth/apple');
    expect(backend.authorization, isNull);
    expect(backend.received, {
      'identityToken': 'apple-token',
      'nonce': 'raw-nonce',
    });
    expect(signedIn.session.accessToken, 'new-token');
    expect(signedIn.session.expiresAt, DateTime.utc(2026, 11, 18, 10));
    expect(signedIn.quota.plan, Plan.free);
    expect(signedIn.quota.remaining, 1);
  });

  test('signing in without Apple sends only a name', () async {
    backend.body =
        '{"accessToken":"dev-token","expiresAt":"2026-11-18T10:00:00Z",'
        '"quota":$_quotaJson}';

    final signedIn = await BackendClient(
      backend.url,
      () async => null,
    ).devSignIn('penda');

    expect(backend.path, '/api/v1/auth/dev');
    expect(backend.received, {'name': 'penda'});
    expect(signedIn.session.accessToken, 'dev-token');
  });

  test('a refused identity says so', () async {
    backend
      ..status = 401
      ..body = '{"code":"invalid_identity","message":"x"}';

    await expectLater(
      client.signInWithApple(identityToken: 't', nonce: 'n'),
      _fails(BackendFailure.invalidIdentity),
    );
    // Signing in is not a session being refused.
    expect(signedOut, 0);
  });

  test('every other call carries the session', () async {
    backend.body = '{"quota":$_quotaJson}';

    final quota = await client.quota();

    expect(backend.method, 'GET');
    expect(backend.path, '/api/v1/me');
    expect(backend.authorization, 'Bearer session-token');
    expect(quota.limit, 1);
    expect(quota.resetsAt, DateTime.utc(2026, 10, 26));
  });

  test('a post sends JSON and returns the JSON answered', () async {
    backend.body = '{"headline":"Well done"}';

    final answer = await client.postJson('/api/v1/english/feedback', {
      'presentation': 'Hello',
    });

    expect(answer, {'headline': 'Well done'});
    expect(backend.method, 'POST');
    expect(backend.received, {'presentation': 'Hello'});
  });

  test('deleting the account sends DELETE and expects nothing back', () async {
    backend
      ..status = 204
      ..body = '';

    await client.deleteAccount();

    expect(backend.method, 'DELETE');
    expect(backend.path, '/api/v1/account');
  });

  test('nothing is sent when signed out', () async {
    final signedOutClient = BackendClient(backend.url, () async => null);

    await expectLater(signedOutClient.quota(), _fails(BackendFailure.signedOut));
    expect(backend.method, isNull);
  });

  test('a session the backend refuses is reported', () async {
    backend
      ..status = 401
      ..body = '{"code":"unauthorized","message":"x"}';

    await expectLater(client.quota(), _fails(BackendFailure.signedOut));
    expect(signedOut, 1);
  });

  for (final (status, body, failure) in [
    (
      429,
      '{"code":"quota_exceeded","message":"x"}',
      BackendFailure.quotaExceeded,
    ),
    (429, '{"code":"rate_limited","message":"x"}', BackendFailure.rateLimited),
    (422, '{"code":"ai_refused","message":"x"}', BackendFailure.aiRefused),
    (502, '{"code":"ai_unavailable","message":"x"}', BackendFailure.aiUnavailable),
    (
      502,
      '{"code":"ai_invalid_response","message":"x"}',
      BackendFailure.aiUnavailable,
    ),
    (503, 'Service Unavailable', BackendFailure.unreachable),
    (500, '{"code":"internal_error","message":"x"}', BackendFailure.unexpected),
  ]) {
    test('HTTP $status ($body) is understood', () async {
      backend
        ..status = status
        ..body = body;

      await expectLater(
        client.postJson('/api/v1/english/feedback', {}),
        _fails(failure),
      );
    });
  }

  test('an answer that is not JSON is unexpected', () async {
    backend.body = '<html>proxy page</html>';

    await expectLater(
      client.postJson('/api/v1/english/feedback', {}),
      _fails(BackendFailure.unexpected),
    );
  });

  test('an answer that is not an object is unexpected', () async {
    backend.body = '[1, 2]';

    await expectLater(
      client.postJson('/api/v1/english/feedback', {}),
      _fails(BackendFailure.unexpected),
    );
  });

  test('a backend that is not there is unreachable', () async {
    final url = backend.url;
    await backend.server.close(force: true);
    final gone = BackendClient(url, () async => _session);

    await expectLater(gone.quota(), _fails(BackendFailure.unreachable));
  });

  test('every failure has something to say', () {
    for (final failure in BackendFailure.values) {
      expect(describeBackendFailure(failure), isNotEmpty);
    }
  });

  group('the quota', () {
    test('says what is left, for the week or the day', () {
      Quota quota(Plan plan, int used, int limit) => Quota(
        plan: plan,
        used: used,
        limit: limit,
        resetsAt: DateTime.utc(2026, 10, 26),
      );
      expect(describeQuota(quota(Plan.free, 0, 1)), '1 correction left this week');
      expect(describeQuota(quota(Plan.free, 1, 1)), 'No corrections left this week');
      expect(describeQuota(quota(Plan.plus, 1, 3)), '2 corrections left today');
      expect(describeQuota(quota(Plan.plus, 5, 3)), 'No corrections left today');
    });

    test('an incomplete quota is refused', () {
      expect(() => Quota.fromJson(null), throwsFormatException);
      expect(
        () => Quota.fromJson({'plan': 'gold', 'used': 0, 'limit': 1}),
        throwsFormatException,
      );
      expect(
        () => Quota.fromJson({'plan': 'free', 'used': 0, 'limit': 1}),
        throwsFormatException,
      );
    });
  });

  group('the nonce', () {
    test('is new every time, and Apple gets its SHA-256 in hex', () {
      final first = newNonce();
      expect(newNonce(), isNot(first));
      expect(
        hashNonce('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
  });

  group('a session', () {
    test('expires at its time, and must not be blank', () {
      expect(_session.isExpiredAt(DateTime.utc(2026, 11, 17)), isFalse);
      expect(_session.isExpiredAt(DateTime.utc(2026, 11, 18)), isTrue);
      expect(
        () => Session(accessToken: '  ', expiresAt: DateTime.utc(2026)),
        throwsArgumentError,
      );
    });
  });
}
