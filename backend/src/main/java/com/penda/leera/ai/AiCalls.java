package com.penda.leera.ai;

import java.util.function.Supplier;

/** How every feature calls the model. */
public final class AiCalls {

    private AiCalls() {}

    /**
     * Runs {@code call} (asking the model and checking its answer), and runs it once more if the
     * answer could not be used: that is usually a one-off. A model that cannot be reached or
     * refuses is not asked again.
     */
    public static <T> T withOneRetry(Supplier<T> call) {
        try {
            return call.get();
        } catch (AiException e) {
            if (e.kind() != AiException.Kind.INVALID_RESPONSE) {
                throw e;
            }
            return call.get();
        }
    }

    /** An answer that does not hold what was asked for. */
    public static AiException invalid(String message) {
        return new AiException(AiException.Kind.INVALID_RESPONSE, message);
    }

    /**
     * Puts {@code content} between {@code <tag>} and {@code </tag>}, so the model reads it as data.
     * The closing tag cannot be faked from inside the content.
     */
    public static String enclosed(String tag, String content) {
        String close = "</" + tag + ">";
        return "<" + tag + ">\n"
                + content.strip().replace(close, "</ " + tag + ">")
                + "\n" + close;
    }
}
