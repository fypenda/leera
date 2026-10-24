import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A session with the backend, opened by signing in with Apple.
class Session {
  Session({required String accessToken, required this.expiresAt})
    : accessToken = accessToken.trim() {
    if (this.accessToken.isEmpty) {
      throw ArgumentError.value(accessToken, 'accessToken', 'Must not be blank.');
    }
  }

  final String accessToken;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

/// Keeps the session. The token is a secret: it is kept in the platform's
/// secure storage (the Keychain on iOS), never in the database.
abstract interface class SessionStore {
  /// The saved session, or null when signed out.
  Future<Session?> read();
  Future<void> write(Session session);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'session.accessToken';
  static const _expiresAtKey = 'session.expiresAt';

  final FlutterSecureStorage _storage;

  @override
  Future<Session?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final expiresAt = DateTime.tryParse(
      await _storage.read(key: _expiresAtKey) ?? '',
    );
    if (token == null || expiresAt == null) return null;
    try {
      final session = Session(accessToken: token, expiresAt: expiresAt);
      // An expired session is as good as none: the person signs in again.
      return session.isExpiredAt(DateTime.now()) ? null : session;
    } on ArgumentError {
      // Something unusable was stored: it is as if nothing were.
      return null;
    }
  }

  @override
  Future<void> write(Session session) async {
    await _storage.write(key: _tokenKey, value: session.accessToken);
    await _storage.write(
      key: _expiresAtKey,
      value: session.expiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}

/// Where the session is kept. Tests replace it with one in memory.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

/// The current session, or null when signed out. Invalidate it after
/// signing in or out.
final sessionProvider = FutureProvider<Session?>(
  (ref) => ref.watch(sessionStoreProvider).read(),
  retry: (retryCount, error) => null,
);

/// The names of the account routes, so features can open them.
const signInRouteName = 'sign-in';
const accountRouteName = 'account';
const plusRouteName = 'plus';
