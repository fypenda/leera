package com.penda.leera.auth;

/**
 * A request that cannot be tied to an account: answered with 401 and {@link #code()}.
 *
 * <p>The message never says which check failed, so it teaches nothing to someone probing.
 */
public class AuthException extends RuntimeException {

    private final String code;

    private AuthException(String code, String message) {
        super(message);
        this.code = code;
    }

    /** No session, or one that is forged, expired or for an account that no longer exists. */
    public static AuthException unauthorized() {
        return new AuthException("unauthorized", "Sign in again.");
    }

    public static AuthException unknownAccount() {
        return unauthorized();
    }

    /** The Apple identity token was refused. */
    public static AuthException invalidIdentity() {
        return new AuthException("invalid_identity", "Sign in with Apple could not be verified.");
    }

    public String code() {
        return code;
    }
}
