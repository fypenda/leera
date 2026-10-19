import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/backend_client.dart';
import 'apple_sign_in.dart';
import 'quota.dart';
import 'session.dart';

/// Signing in and out, and deleting the account.
class AuthActions {
  AuthActions(this._ref);

  final Ref _ref;

  /// Signs in with Apple. Returns false if the person closed Apple's sheet;
  /// throws [BackendException] if the backend refused or could not be
  /// reached.
  Future<bool> signInWithApple() async {
    final nonce = newNonce();
    final identityToken = await _ref
        .read(appleSignInProvider)
        .identityToken(hashedNonce: hashNonce(nonce));
    if (identityToken == null) return false;

    final signedIn = await _ref
        .read(backendClientProvider)
        .signInWithApple(identityToken: identityToken, nonce: nonce);
    await _ref.read(sessionStoreProvider).write(signedIn.session);
    _ref.invalidate(sessionProvider);
    _ref.invalidate(quotaProvider);
    return true;
  }

  /// Forgets the session on this device. The account stays.
  Future<void> signOut() async {
    await _ref.read(sessionStoreProvider).clear();
    _ref.invalidate(sessionProvider);
    _ref.invalidate(quotaProvider);
  }

  /// Deletes the account on the backend, then signs out. The sessions and
  /// corrections stored on this device stay on it.
  Future<void> deleteAccount() async {
    await _ref.read(backendClientProvider).deleteAccount();
    await signOut();
  }
}

final authActionsProvider = Provider<AuthActions>(AuthActions.new);

/// Where the account stands with its quota. Invalidate it after a
/// correction.
///
/// A failure is not retried automatically: the page that shows it offers to
/// try again.
final quotaProvider = FutureProvider<Quota>((ref) async {
  // Asked again whenever the session changes.
  final session = await ref.watch(sessionProvider.future);
  if (session == null) {
    throw const BackendException(BackendFailure.signedOut);
  }
  return ref.read(backendClientProvider).quota();
}, retry: (retryCount, error) => null);
