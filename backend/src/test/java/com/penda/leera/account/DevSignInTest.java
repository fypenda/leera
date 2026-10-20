package com.penda.leera.account;

import static org.assertj.core.api.Assertions.assertThat;
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

    @Test
    void aDevelopmentAccountIsOpenedByName() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/dev")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"penda-dev\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quota.plan").value("free"))
                .andReturn()
                .getResponse()
                .getContentAsString();
        String bearer = "Bearer " + mapper.readTree(body).get("accessToken").asText();

        assertThat(accounts.findByAppleSubject("dev:penda-dev")).isPresent();
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk());
    }

    @Test
    void theNameIsShortAndPlain() throws Exception {
        mvc.perform(post("/api/v1/auth/dev")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"Not Allowed!\"}"))
                .andExpect(status().isBadRequest());
    }
}
