package com.penda.leera.account;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.penda.leera.ai.AiClient;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Signing in without Apple behind {@code LEERA_DEV_SIGN_IN_TOKEN}, as on a test backend. */
@SpringBootTest(
        properties = {
            "leera.auth.dev-sign-in=true",
            "leera.auth.dev-sign-in-token=" + DevSignInTokenTest.TOKEN
        })
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DevSignInTokenTest {

    static final String TOKEN = "a-test-token-that-is-long-enough-0123";

    @Autowired MockMvc mvc;
    @Autowired AccountRepository accounts;
    @MockitoBean AiClient ai;

    /** From elsewhere than this machine, as through a host's proxy. */
    private static MockHttpServletRequestBuilder signIn(String name) {
        return post("/api/v1/auth/dev")
                .with(request -> {
                    request.setRemoteAddr("203.0.113.5");
                    return request;
                })
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\": \"" + name + "\"}");
    }

    @Test
    void theRightTokenSignsIn() throws Exception {
        mvc.perform(signIn("tester").header(DevSignInController.TOKEN_HEADER, TOKEN))
                .andExpect(status().isOk());

        assertThat(accounts.findByAppleSubject("dev:tester")).isPresent();
    }

    @Test
    void noTokenOrAWrongOneIsRefused() throws Exception {
        mvc.perform(signIn("nobody")).andExpect(status().isUnauthorized());
        mvc.perform(signIn("nobody").header(DevSignInController.TOKEN_HEADER, TOKEN + "x"))
                .andExpect(status().isUnauthorized());

        assertThat(accounts.findByAppleSubject("dev:nobody")).isEmpty();
    }

    @Test
    void evenFromThisMachineTheTokenIsAskedFor() throws Exception {
        mvc.perform(post("/api/v1/auth/dev")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"local\"}"))
                .andExpect(status().isUnauthorized());
    }
}
