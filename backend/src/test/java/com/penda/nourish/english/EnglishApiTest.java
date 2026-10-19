package com.penda.nourish.english;

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
import com.penda.nourish.ai.AiClient;
import com.penda.nourish.ai.AiException;
import com.penda.nourish.security.AppTokenFilter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EnglishApiTest {

    private static final String TOKEN = "test-token";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
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

    @BeforeEach
    void setUp() throws Exception {
        when(ai.model()).thenReturn("claude-test");
        when(ai.completeJson(anyString(), anyString(), any())).thenReturn(mapper.readTree(ANSWER));
    }

    @Test
    void theHealthCheckIsOpen() throws Exception {
        mvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ok"));
    }

    @Test
    void pingNeedsTheToken() throws Exception {
        mvc.perform(get("/api/v1/ping")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/ping").header(AppTokenFilter.HEADER, TOKEN))
                .andExpect(status().isOk());
    }

    @Test
    void feedbackIsRefusedWithoutTheRightToken() throws Exception {
        mvc.perform(post("/api/v1/english/feedback")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(REQUEST))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("unauthorized"));
        mvc.perform(post("/api/v1/english/feedback")
                        .header(AppTokenFilter.HEADER, "wrong")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(REQUEST))
                .andExpect(status().isUnauthorized());

        verify(ai, never()).completeJson(anyString(), anyString(), any());
    }

    @Test
    void aPresentationIsCorrected() throws Exception {
        mvc.perform(post("/api/v1/english/feedback")
                        .header(AppTokenFilter.HEADER, TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(REQUEST))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.promptVersion").value(FeedbackService.PROMPT_VERSION))
                .andExpect(jsonPath("$.model").value("claude-test"))
                .andExpect(jsonPath("$.estimatedLevel").value("B2"))
                .andExpect(jsonPath("$.scores.structure").value(8))
                .andExpect(jsonPath("$.corrections[0].fix").value("allows"))
                .andExpect(jsonPath("$.createdAt").isString());
    }

    @Test
    void anInvalidRequestNamesItsFieldsButNotTheirContent() throws Exception {
        mvc.perform(post("/api/v1/english/feedback")
                        .header(AppTokenFilter.HEADER, TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"topicTitle\": \"\", \"formatLabel\": \"Essay\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("invalid_request"))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("presentation")));

        mvc.perform(post("/api/v1/english/feedback")
                        .header(AppTokenFilter.HEADER, TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("not json"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void failuresOfTheModelHaveTheirOwnCodes() throws Exception {
        when(ai.completeJson(anyString(), anyString(), any()))
                .thenThrow(new AiException(AiException.Kind.UNAVAILABLE, "down"));
        mvc.perform(post("/api/v1/english/feedback")
                        .header(AppTokenFilter.HEADER, TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(REQUEST))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.code").value("ai_unavailable"));

        // The mock already throws: stubbing it again with when() would call it.
        doThrow(new AiException(AiException.Kind.REFUSED, "no"))
                .when(ai)
                .completeJson(anyString(), anyString(), any());
        mvc.perform(post("/api/v1/english/feedback")
                        .header(AppTokenFilter.HEADER, TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(REQUEST))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("ai_refused"));
    }
}
