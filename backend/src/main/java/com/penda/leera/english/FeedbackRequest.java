package com.penda.leera.english;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * A presentation to correct, written or spoken then transcribed, with what the model needs to judge
 * it.
 *
 * <p>Only what the correction needs is sent: no notes, no identifier. About the person, only
 * what shapes the correction, all of it optional: see {@link Learner}.
 */
public record FeedbackRequest(
        @NotBlank @Size(max = 300) String topicTitle,
        @Size(max = 1000) String topicPrompt,
        @NotBlank @Size(max = 100) String formatLabel,
        @NotBlank @Size(max = 100) String formatConstraint,
        @NotBlank @Size(max = 20_000) String presentation,
        /* Tags of mistakes made in earlier sessions, most frequent first. Optional. */
        @Size(max = 10) List<@NotBlank @Size(max = 40) String> recurringMistakes,
        /* True when the presentation was spoken and transcribed by speech recognition. Optional. */
        Boolean spoken,
        /* Who is learning, so the correction fits them. Optional, and each field too. */
        @Valid Learner learner) {

    /**
     * What the correction is tuned to.
     *
     * @param level the latest CEFR level estimated, or the one the person gave
     * @param levelSelfAssessed true when {@code level} is the person's own estimate
     * @param goal why they learn: work, studies, exam, travel or everyday
     * @param firstLanguage their first language, in English ("French"), to spot its usual traps
     */
    public record Learner(
            @Pattern(regexp = "A2|B1|B1\\+|B2|B2\\+|C1|C1\\+|C2") String level,
            Boolean levelSelfAssessed,
            @Pattern(regexp = "work|studies|exam|travel|everyday") String goal,
            @Size(max = 40) @Pattern(regexp = "[\\p{L} '-]{1,40}") String firstLanguage) {}

    public Learner learnerOrNone() {
        return learner == null ? new Learner(null, null, null, null) : learner;
    }

    public List<String> recurringMistakesOrEmpty() {
        return recurringMistakes == null ? List.of() : recurringMistakes;
    }

    public boolean isSpoken() {
        return Boolean.TRUE.equals(spoken);
    }
}
