package com.penda.nourish.english;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * A presentation to correct, written or spoken then transcribed, with what the model needs to judge
 * it.
 *
 * <p>Only what the correction needs is sent: no notes, no identifier, nothing about the person.
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
        Boolean spoken) {

    public List<String> recurringMistakesOrEmpty() {
        return recurringMistakes == null ? List.of() : recurringMistakes;
    }

    public boolean isSpoken() {
        return Boolean.TRUE.equals(spoken);
    }
}
