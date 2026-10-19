package com.penda.leera.auth;

/** Checks an identity token from Sign in with Apple. */
public interface AppleIdentityVerifier {

    /**
     * The Apple user id ({@code sub}) of a valid identity token, or {@link
     * AuthException#invalidIdentity()}.
     *
     * @param identityToken the token the app received from Apple
     * @param rawNonce the nonce the app generated; Apple's token holds its SHA-256, in hex
     */
    String verify(String identityToken, String rawNonce);
}
