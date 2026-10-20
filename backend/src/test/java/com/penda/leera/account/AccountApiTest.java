package com.penda.leera.account;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.leera.ai.AiClient;
import com.penda.leera.auth.AppleIdentityVerifier;
import com.penda.leera.auth.AuthException;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountApiTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AccountRepository accounts;
    @MockitoBean AppleIdentityVerifier apple;
    @MockitoBean AiClient ai;

    /** Signs in with an identity token Apple vouches for, and returns the session. */
    private String signIn(String identityToken, String nonce) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/apple")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(new AccountController.AppleSignInRequest(
                                identityToken, nonce))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.expiresAt").isString())
                .andExpect(jsonPath("$.quota.plan").value("free"))
                .andExpect(jsonPath("$.quota.limit").value(1))
                .andExpect(jsonPath("$.quota.resetsAt").isString())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return "Bearer " + mapper.readTree(body).get("accessToken").asText();
    }

    @Test
    void signingInTwiceWithTheSameAppleIdOpensTheSameAccount() throws Exception {
        String subject = "apple." + UUID.randomUUID();
        when(apple.verify("token-1", "nonce-1")).thenReturn(subject);
        when(apple.verify("token-2", "nonce-2")).thenReturn(subject);

        String first = signIn("token-1", "nonce-1");
        String second = signIn("token-2", "nonce-2");

        assertThat(accounts.findByAppleSubject(subject)).isPresent();
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, first))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quota.used").value(0));
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, second))
                .andExpect(status().isOk());
    }

    @Test
    void aTokenAppleDoesNotVouchForIsRefused() throws Exception {
        when(apple.verify("forged", "nonce")).thenThrow(AuthException.invalidIdentity());

        mvc.perform(post("/api/v1/auth/apple")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identityToken\": \"forged\", \"nonce\": \"nonce\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("invalid_identity"));
        mvc.perform(post("/api/v1/auth/apple")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identityToken\": \"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void signingInWithoutAppleIsOffByDefault() throws Exception {
        mvc.perform(post("/api/v1/auth/dev")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"penda\"}"))
                // No such endpoint: 404, or 405 from the static resources.
                .andExpect(status().is4xxClientError())
                .andExpect(jsonPath("$.accessToken").doesNotExist());
    }

    @Test
    void theQuotaNeedsASession() throws Exception {
        mvc.perform(get("/api/v1/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("unauthorized"));
    }

    @Test
    void deletingTheAccountEndsItsSessions() throws Exception {
        String subject = "apple." + UUID.randomUUID();
        when(apple.verify("token", "nonce")).thenReturn(subject);
        String session = signIn("token", "nonce");

        mvc.perform(delete("/api/v1/account").header(HttpHeaders.AUTHORIZATION, session))
                .andExpect(status().isNoContent());

        assertThat(accounts.findByAppleSubject(subject)).isEmpty();
        mvc.perform(get("/api/v1/me").header(HttpHeaders.AUTHORIZATION, session))
                .andExpect(status().isUnauthorized());
    }
}
