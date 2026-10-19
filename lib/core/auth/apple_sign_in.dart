import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Sign in with Apple, behind an interface so tests can do without Apple.
abstract interface class AppleSignIn {
  /// Shows Apple's sheet and returns the identity token, or null if the
  /// person closed it.
  ///
  /// [hashedNonce] goes into the token, so the backend can check that the
  /// token was made for this request.
  Future<String?> identityToken({required String hashedNonce});
}

class SystemAppleSignIn implements AppleSignIn {
  const SystemAppleSignIn();

  @override
  Future<String?> identityToken({required String hashedNonce}) async {
    try {
      // No name, no email: Leera needs neither.
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [],
        nonce: hashedNonce,
      );
      return credential.identityToken;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }
}

final appleSignInProvider = Provider<AppleSignIn>(
  (ref) => const SystemAppleSignIn(),
);

/// A random nonce, from a secure source, safe to put in JSON and URLs.
String newNonce() {
  final random = Random.secure();
  return base64UrlEncode([for (var i = 0; i < 32; i++) random.nextInt(256)]);
}

/// What Apple is given in place of the nonce: its SHA-256, in hex.
String hashNonce(String nonce) => sha256.convert(utf8.encode(nonce)).toString();
