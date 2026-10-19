package com.penda.leera.ai;

/** Something went wrong while asking the model. {@link Kind} says what, for the response. */
public class AiException extends RuntimeException {

    public enum Kind {
        /** The provider could not be reached, timed out, or answered with an error. */
        UNAVAILABLE,
        /** The model declined to answer. */
        REFUSED,
        /** The model answered, but not with what was asked for. */
        INVALID_RESPONSE
    }

    private final Kind kind;

    public AiException(Kind kind, String message) {
        super(message);
        this.kind = kind;
    }

    public AiException(Kind kind, String message, Throwable cause) {
        super(message, cause);
        this.kind = kind;
    }

    public Kind kind() {
        return kind;
    }
}
