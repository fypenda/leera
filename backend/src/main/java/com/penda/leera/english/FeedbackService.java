package com.penda.leera.english;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.leera.ai.AiCalls;
import com.penda.leera.ai.AiClient;
import com.penda.leera.ai.AiException;
import com.penda.leera.ai.PromptTemplate;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;

/**
 * Corrects a written presentation with the model, using a versioned prompt and schema.
 *
 * <p>The model's answer is checked and tidied before it goes back to the app: scores are kept
 * between 0 and 10, lists are kept short, and incomplete items are dropped. An answer that cannot
 * be used is asked for once more before giving up.
 */
@Service
public class FeedbackService {

    public static final String PROMPT_VERSION = "feedback-v1";

    static final int MAX_CORRECTIONS = 12;
    static final int MAX_VOCABULARY = 5;
    static final int MAX_QUESTIONS = 2;

    private final AiClient ai;
    private final Clock clock;
    private final PromptTemplate prompt;

    public FeedbackService(AiClient ai, ObjectMapper mapper, Clock clock) {
        this.ai = ai;
        this.clock = clock;
        this.prompt = PromptTemplate.load("english", PROMPT_VERSION, mapper);
    }

    public FeedbackResponse correct(FeedbackRequest request) {
        String user = userMessage(request);
        return AiCalls.withOneRetry(
                () -> normalized(ai.completeJson(prompt.system(), user, prompt.schema())));
    }

    /** How a transcript is to be read: it is speech, and the transcription makes its own errors. */
    static final String SPOKEN =
            "spoken aloud, then transcribed automatically by speech recognition. Punctuation, "
                    + "capitalisation, spelling and words that sound alike come from the transcription: "
                    + "never correct those. Judge it as spoken English: grammar, vocabulary, "
                    + "naturalness, structure and content.";

    String userMessage(FeedbackRequest request) {
        var recurring = request.recurringMistakesOrEmpty();
        return """
                Topic: %s
                What to find out: %s
                Format: %s (%s)
                Delivery: %s
                Recurring mistakes from past sessions: %s

                <presentation>
                %s
                </presentation>
                """
                .formatted(
                        request.topicTitle().strip(),
                        blankToNone(request.topicPrompt()),
                        request.formatLabel().strip(),
                        request.formatConstraint().strip(),
                        request.isSpoken() ? SPOKEN : "written",
                        recurring.isEmpty() ? "none yet" : String.join(", ", recurring),
                        // The closing tag cannot be faked from inside the text.
                        request.presentation().strip().replace("</presentation>", "</ presentation>"));
    }

    FeedbackResponse normalized(JsonNode answer) {
        String level = text(answer, "estimatedLevel");
        String headline = text(answer, "headline");
        String summary = text(answer, "summary");
        JsonNode scores = answer.path("scores");
        if (level.isEmpty() || headline.isEmpty() || summary.isEmpty() || !scores.isObject()) {
            throw invalid("The correction is missing its level, headline, summary or scores.");
        }

        var corrections = new ArrayList<FeedbackResponse.Correction>();
        for (JsonNode item : answer.path("corrections")) {
            String original = text(item, "original");
            String corrected = text(item, "corrected");
            String explanation = text(item, "explanation");
            // A correction that changes nothing, or explains nothing, helps nobody.
            if (original.isEmpty() || corrected.isEmpty() || explanation.isEmpty()
                    || original.equals(corrected)) {
                continue;
            }
            String kind = text(item, "kind").equals("naturalness") ? "naturalness" : "grammar";
            corrections.add(
                    new FeedbackResponse.Correction(
                            kind,
                            original,
                            corrected,
                            text(item, "mistake"),
                            text(item, "fix"),
                            explanation,
                            tag(text(item, "tag"))));
            if (corrections.size() == MAX_CORRECTIONS) {
                break;
            }
        }

        var vocabulary = new ArrayList<FeedbackResponse.VocabularyItem>();
        for (JsonNode item : answer.path("vocabulary")) {
            String expression = text(item, "expression");
            String meaning = text(item, "meaning");
            if (expression.isEmpty() || meaning.isEmpty()) {
                continue;
            }
            vocabulary.add(
                    new FeedbackResponse.VocabularyItem(expression, meaning, text(item, "example")));
            if (vocabulary.size() == MAX_VOCABULARY) {
                break;
            }
        }

        return new FeedbackResponse(
                PROMPT_VERSION,
                ai.model(),
                clock.instant(),
                level,
                headline,
                summary,
                new FeedbackResponse.Scores(
                        score(scores, "grammar"),
                        score(scores, "vocabulary"),
                        score(scores, "naturalness"),
                        score(scores, "structure"),
                        score(scores, "content")),
                List.copyOf(corrections),
                List.copyOf(vocabulary),
                strings(answer.path("followUpQuestions"), MAX_QUESTIONS),
                strings(answer.path("recurringMistakesSeen"), 10).stream()
                        .map(FeedbackService::tag)
                        .toList());
    }

    private static int score(JsonNode scores, String name) {
        JsonNode value = scores.path(name);
        if (!value.isNumber()) {
            throw invalid("The score for " + name + " is missing.");
        }
        return Math.max(0, Math.min(10, (int) Math.round(value.asDouble())));
    }

    private static List<String> strings(JsonNode array, int max) {
        var result = new ArrayList<String>();
        for (JsonNode item : array) {
            String value = item.asText("").strip();
            if (!value.isEmpty()) {
                result.add(value);
            }
            if (result.size() == max) {
                break;
            }
        }
        return List.copyOf(result);
    }

    private static String text(JsonNode node, String field) {
        JsonNode value = node.path(field);
        return value.isTextual() ? value.asText().strip() : "";
    }

    /** "False Friends" and "false-friends" are the same tag. */
    private static String tag(String raw) {
        String tag = raw.toLowerCase(Locale.ROOT).strip().replaceAll("[^a-z0-9]+", "-");
        tag = tag.replaceAll("^-+|-+$", "");
        return tag.isEmpty() ? "other" : tag.length() > 40 ? tag.substring(0, 40) : tag;
    }

    private static String blankToNone(String value) {
        return value == null || value.isBlank() ? "not given" : value.strip();
    }

    private static AiException invalid(String message) {
        return new AiException(AiException.Kind.INVALID_RESPONSE, message);
    }
}
