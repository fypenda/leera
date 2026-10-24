package com.penda.leera.account;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.leera.ai.AiClient;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/** With {@code leera.auth.dev-sign-in} on. {@link AccountApiTest} checks that it is off by default. */
@SpringBootTest(properties = "leera.auth.dev-sign-in=true")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DevSignInTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AccountRepository accounts;
    @MockitoBean AiClient ai;

    private static final String REQUEST =
            """
            {"topicTitle": "How jazz was born in New Orleans",
             "formatLabel": "Voice note",
             "formatConstraint": "2 minutes",
             "presentation": "Jazz was born in New Orleans."}
            """;

    private static final String ANSWER =
            """
            {"estimatedLevel": "B2", "headline": "Good", "summary": "Clear.",
             "scores": {"grammar": 7, "vocabulary": 7, "naturalness": 7, "structure": 7, "content": 7},
             "corrections": [], "vocabulary": [], "followUpQuestions": [], "recurringMistakesSeen": []}
            """;

    private String devBearer(String name) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/dev")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"" + name + "\"}"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return "Bearer " + mapper.readTree(body).get("accessToken").asText();
    }

    @Test
    void aDevelopmentAccountIsOpenedByName() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/dev")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"penda-dev\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quota.plan").value("dev"))
                .andReturn()
                .getResponse()
                .getContentAsString();
        String bearer = "Bearer " + mapper.readTree(body).get("accessToken").asText();

        assertThat(accounts.findByAppleSubject("dev:penda-dev")).isPresent();
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk());
    }

    @Test
    void aDevelopmentAccountHasNoQuota() throws Exception {
        when(ai.model()).thenReturn("claude-test");
        when(ai.completeJson(anyString(), anyString(), any())).thenReturn(mapper.readTree(ANSWER));
        String bearer = devBearer("unlimited");

        // The free plan allows 1 a week: a development account goes on.
        for (int i = 0; i < 3; i++) {
            mvc.perform(post("/api/v1/english/feedback")
                            .header(HttpHeaders.AUTHORIZATION, bearer)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(REQUEST))
                    .andExpect(status().isOk());
        }
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(jsonPath("$.quota.plan").value("dev"))
                .andExpect(jsonPath("$.quota.used").value(3));
    }

    @Test
    void theNameIsShortAndPlain() throws Exception {
        mvc.perform(post("/api/v1/auth/dev")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"Not Allowed!\"}"))
                .andExpect(status().isBadRequest());
    }
}
