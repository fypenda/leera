package com.penda.leera.security;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.penda.leera.ai.AiClient;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = "leera.rate-limit.requests-per-hour=2")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class RateLimitTest {

    @Autowired MockMvc mvc;
    @MockitoBean AiClient ai;

    @Test
    void authenticatedRequestsAreCappedPerHourAndRefusedOnesDoNotCount() throws Exception {
        // Refused for their token: they use nothing up.
        for (int i = 0; i < 5; i++) {
            mvc.perform(get("/api/v1/ping")).andExpect(status().isUnauthorized());
        }
        // The health check is never limited.
        for (int i = 0; i < 5; i++) {
            mvc.perform(get("/api/v1/health")).andExpect(status().isOk());
        }

        mvc.perform(get("/api/v1/ping").header(AppTokenFilter.HEADER, "test-token"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/ping").header(AppTokenFilter.HEADER, "test-token"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/ping").header(AppTokenFilter.HEADER, "test-token"))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", "3600"))
                .andExpect(jsonPath("$.code").value("rate_limited"));
    }
}
