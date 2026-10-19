package com.penda.leera.security;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.penda.leera.account.AccountRepository;
import com.penda.leera.ai.AiClient;
import com.penda.leera.auth.SessionTokens;
import com.penda.leera.support.TestSessions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = "leera.rate-limit.requests-per-hour=2")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class RateLimitTest {

    @Autowired MockMvc mvc;
    @Autowired AccountRepository accounts;
    @Autowired SessionTokens sessions;
    @MockitoBean AiClient ai;

    @Test
    void authenticatedRequestsAreCappedPerHourAndRefusedOnesDoNotCount() throws Exception {
        // Refused for their session: they use nothing up.
        for (int i = 0; i < 5; i++) {
            mvc.perform(get("/api/v1/me")).andExpect(status().isUnauthorized());
        }
        // The health check is never limited.
        for (int i = 0; i < 5; i++) {
            mvc.perform(get("/api/v1/health")).andExpect(status().isOk());
        }

        String bearer = TestSessions.bearer(sessions, TestSessions.newAccount(accounts));
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", "3600"))
                .andExpect(jsonPath("$.code").value("rate_limited"));
    }
}
