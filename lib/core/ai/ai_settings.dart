import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the app's AI backend is, and the secret it expects.
///
/// Nothing is ever sent to an AI service until these are set: entering them
/// is the person's consent.
class AiSettings {
  AiSettings({required String baseUrl, required String appToken})
    : baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), ''),
      appToken = appToken.trim() {
    final uri = Uri.tryParse(this.baseUrl);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'Must be an http or https address.',
      );
    }
    if (this.appToken.isEmpty) {
      throw ArgumentError.value(appToken, 'appToken', 'Must not be blank.');
    }
  }

  /// The backend's address, without a trailing slash.
  final String baseUrl;
  final String appToken;

  Uri resolve(String path) => Uri.parse('$baseUrl$path');
}

/// Keeps the AI settings. The token is a secret: it is kept in the
/// platform's secure storage (the Keychain on iOS), never in the database.
abstract interface class AiSettingsStore {
  /// The saved settings, or null if there are none.
  Future<AiSettings?> read();
  Future<void> write(AiSettings settings);
  Future<void> clear();
}

class SecureAiSettingsStore implements AiSettingsStore {
  SecureAiSettingsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _baseUrlKey = 'ai.baseUrl';
  static const _tokenKey = 'ai.appToken';

  final FlutterSecureStorage _storage;

  @override
  Future<AiSettings?> read() async {
    final baseUrl = await _storage.read(key: _baseUrlKey);
    final token = await _storage.read(key: _tokenKey);
    if (baseUrl == null || token == null) return null;
    try {
      return AiSettings(baseUrl: baseUrl, appToken: token);
    } on ArgumentError {
      // Something unusable was stored: it is as if nothing were.
      return null;
    }
  }

  @override
  Future<void> write(AiSettings settings) async {
    await _storage.write(key: _baseUrlKey, value: settings.baseUrl);
    await _storage.write(key: _tokenKey, value: settings.appToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _baseUrlKey);
    await _storage.delete(key: _tokenKey);
  }
}

/// Where the AI settings are kept. Tests replace it with one in memory.
final aiSettingsStoreProvider = Provider<AiSettingsStore>(
  (ref) => SecureAiSettingsStore(),
);

/// The saved AI settings, or null when the AI is not set up. Invalidate it
/// after a change.
final aiSettingsProvider = FutureProvider<AiSettings?>(
  (ref) => ref.watch(aiSettingsStoreProvider).read(),
);

/// The name of the AI settings page's route, so features can open it.
const aiSettingsRouteName = 'ai-settings';
