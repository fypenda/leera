package com.penda.leera.english;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.leera.account.Account;
import com.penda.leera.account.AccountRepository;
import com.penda.leera.ai.AiClient;
import com.penda.leera.ai.AiException;
import com.penda.leera.auth.SessionTokens;
import com.penda.leera.support.TestSessions;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EnglishApiTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AccountRepository accounts;
    @Autowired SessionTokens sessions;
    @MockitoBean AiClient ai;

    private static final String REQUEST =
            """
            {"topicTitle": "How the Suez Canal changed world trade",
             "topicPrompt": "Find out who built it.",
             "formatLabel": "Short essay",
             "formatConstraint": "250 to 350 words",
             "presentation": "It permits to ships to avoid Africa.",
             "recurringMistakes": ["prepositions"]}
            """;

    private static final String ANSWER =
            """
            {"estimatedLevel": "B2", "headline": "Good start 👍", "summary": "Clear. Prepositions.",
             "scores": {"grammar": 6, "vocabulary": 7, "naturalness": 6, "structure": 8, "content": 7},
             "corrections": [{"kind": "grammar", "original": "It permits to ships",
               "corrected": "It allows ships", "mistake": "permits to", "fix": "allows",
               "explanation": "A calque.", "tag": "false-friends"}],
             "vocabulary": [], "followUpQuestions": [], "recurringMistakesSeen": []}
            """;

    private Account account;
    private String bearer;

    @BeforeEach
    void setUp() throws Exception {
        when(ai.model()).thenReturn("claude-test");
        when(ai.completeJson(anyString(), anyString(), any())).thenReturn(mapper.readTree(ANSWER));
        account = TestSessions.newAccount(accounts);
        bearer = TestSessions.bearer(sessions, account);
    }

    private ResultActions askFeedback(String authorization, String body) throws Exception {
        var request = post("/api/v1/english/feedback")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body);
        if (authorization != null) {
            request.header(HttpHeaders.AUTHORIZATION, authorization);
        }
        return mvc.perform(request);
    }

    @Test
    void theHealthCheckIsOpen() throws Exception {
        mvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ok"));
    }

    @Test
    void feedbackIsRefusedWithoutAValidSession() throws Exception {
        askFeedback(null, REQUEST)
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("unauthorized"));
        askFeedback("Bearer forged.token.value", REQUEST).andExpect(status().isUnauthorized());
        askFeedback("Basic abc", REQUEST).andExpect(status().isUnauthorized());

        verify(ai, never()).completeJson(anyString(), anyString(), any());
    }

    @Test
    void aSessionStopsWorkingOnceItsAccountIsDeleted() throws Exception {
        accounts.delete(account.id());

        askFeedback(bearer, REQUEST).andExpect(status().isUnauthorized());
        verify(ai, never()).completeJson(anyString(), anyString(), any());
    }

    @Test
    void aPresentationIsCorrected() throws Exception {
        askFeedback(bearer, REQUEST)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.promptVersion").value(FeedbackService.PROMPT_VERSION))
                .andExpect(jsonPath("$.model").value("claude-test"))
                .andExpect(jsonPath("$.estimatedLevel").value("B2"))
                .andExpect(jsonPath("$.scores.structure").value(8))
                .andExpect(jsonPath("$.corrections[0].fix").value("allows"))
                .andExpect(jsonPath("$.createdAt").isString());
    }

    @Test
    void theFreePlanAllowsOneCorrectionAWeek() throws Exception {
        askFeedback(bearer, REQUEST).andExpect(status().isOk());

        askFeedback(bearer, REQUEST)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value("quota_exceeded"));
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quota.plan").value("free"))
                .andExpect(jsonPath("$.quota.used").value(1))
                .andExpect(jsonPath("$.quota.limit").value(1));
    }

    @Test
    void leeraPlusAllowsThreeADay() throws Exception {
        accounts.setPlusUntil(account.id(), Instant.now().plus(30, ChronoUnit.DAYS));

        for (int i = 0; i < 3; i++) {
            askFeedback(bearer, REQUEST).andExpect(status().isOk());
        }
        askFeedback(bearer, REQUEST)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value("quota_exceeded"));
    }

    @Test
    void anInvalidRequestIsNotCounted() throws Exception {
        askFeedback(bearer, "{\"topicTitle\": \"\", \"formatLabel\": \"Essay\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("invalid_request"))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("presentation")));
        askFeedback(bearer, "not json").andExpect(status().isBadRequest());

        askFeedback(bearer, REQUEST).andExpect(status().isOk());
    }

    @Test
    void failuresOfTheModelHaveTheirOwnCodesAndAreNotCounted() throws Exception {
        when(ai.completeJson(anyString(), anyString(), any()))
                .thenThrow(new AiException(AiException.Kind.UNAVAILABLE, "down"));
        askFeedback(bearer, REQUEST)
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.code").value("ai_unavailable"));

        // The mock already throws: stubbing it again with when() would call it.
        doThrow(new AiException(AiException.Kind.REFUSED, "no"))
                .when(ai)
                .completeJson(anyString(), anyString(), any());
        askFeedback(bearer, REQUEST)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("ai_refused"));

        // Neither used up the free correction of the week.
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(jsonPath("$.quota.used").value(0));
    }
}
