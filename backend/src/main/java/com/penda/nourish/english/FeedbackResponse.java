package com.penda.nourish.english;

import java.time.Instant;
import java.util.List;

/**
 * The correction of one presentation, as the app receives and stores it.
 *
 * <p>These names are a contract with the app, which keeps responses on the device: a change that
 * is not an addition needs a new prompt version and a change in the app.
 */
public record FeedbackResponse(
        String promptVersion,
        String model,
        Instant createdAt,
        String estimatedLevel,
        String headline,
        String summary,
        Scores scores,
        List<Correction> corrections,
        List<VocabularyItem> vocabulary,
        List<String> followUpQuestions,
        List<String> recurringMistakesSeen) {

    /** Each from 0 to 10. */
    public record Scores(int grammar, int vocabulary, int naturalness, int structure, int content) {}

    /**
     * A sentence as written ({@code original}) and as it should be ({@code corrected}). {@code
     * mistake} is found in {@code original} and {@code fix} in {@code corrected} when the model got
     * them right; the app highlights them only then.
     */
    public record Correction(
            String kind,
            String original,
            String corrected,
            String mistake,
            String fix,
            String explanation,
            String tag) {}

    public record VocabularyItem(String expression, String meaning, String example) {}
}
