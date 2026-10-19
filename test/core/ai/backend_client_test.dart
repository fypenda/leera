import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leera/core/ai/ai_settings.dart';
import 'package:leera/core/ai/backend_client.dart';

/// A local server that answers every request with [status] and [body], and
/// remembers the last request.
class _Backend {
  late HttpServer server;
  int status = 200;
  String body = '{"status":"ok"}';
  String? token;
  String? method;
  String? path;
  Object? received;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      token = request.headers.value('X-App-Token');
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

  AiSettings settings({String token = 'secret'}) => AiSettings(
    baseUrl: 'http://${server.address.host}:${server.port}/',
    appToken: token,
  );
}

Matcher _fails(BackendFailure failure) => throwsA(
  isA<BackendException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  late _Backend backend;
  late BackendClient client;

  setUp(() async {
    backend = _Backend();
    await backend.start();
    client = BackendClient(() async => backend.settings());
  });
  tearDown(() => backend.server.close(force: true));

  test('a ping carries the token', () async {
    await client.ping();

    expect(backend.method, 'GET');
    expect(backend.path, '/api/v1/ping');
    expect(backend.token, 'secret');
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

  test('nothing is sent without settings', () async {
    final unset = BackendClient(() async => null);

    await expectLater(unset.ping(), _fails(BackendFailure.notConfigured));
    expect(backend.method, isNull);
  });

  for (final (status, body, failure) in [
    (401, '{"code":"unauthorized","message":"x"}', BackendFailure.unauthorized),
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

      await expectLater(client.ping(), _fails(failure));
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
    final port = backend.server.port;
    await backend.server.close(force: true);
    final gone = BackendClient(
      () async =>
          AiSettings(baseUrl: 'http://127.0.0.1:$port', appToken: 'secret'),
    );

    await expectLater(gone.ping(), _fails(BackendFailure.unreachable));
  });

  test('every failure has something to say', () {
    for (final failure in BackendFailure.values) {
      expect(describeBackendFailure(failure), isNotEmpty);
    }
  });

  group('settings', () {
    test('the address loses its trailing slashes and must be http(s)', () {
      final settings = AiSettings(
        baseUrl: ' https://api.example.com// ',
        appToken: ' token ',
      );
      expect(settings.baseUrl, 'https://api.example.com');
      expect(settings.appToken, 'token');
      expect(
        settings.resolve('/api/v1/ping').toString(),
        'https://api.example.com/api/v1/ping',
      );

      expect(
        () => AiSettings(baseUrl: 'ftp://x', appToken: 't'),
        throwsArgumentError,
      );
      expect(
        () => AiSettings(baseUrl: 'not an address', appToken: 't'),
        throwsArgumentError,
      );
      expect(
        () => AiSettings(baseUrl: 'http://x', appToken: '  '),
        throwsArgumentError,
      );
    });
  });
}
