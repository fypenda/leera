package com.penda.nourish.ai;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.nourish.config.NourishProperties;
import java.time.Duration;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class AnthropicAiClientTest {

    private final ObjectMapper mapper = new ObjectMapper();
    private MockRestServiceServer server;
    private AnthropicAiClient client;
    private JsonNode schema;

    @BeforeEach
    void setUp() throws Exception {
        RestClient.Builder builder = RestClient.builder();
        server = MockRestServiceServer.bindTo(builder).build();
        var settings =
                new NourishProperties.Anthropic(
                        "secret-key", "https://api.example.test", "claude-test", 2048, Duration.ofSeconds(5));
        client = new AnthropicAiClient(builder, settings, mapper);
        schema = mapper.readTree("{\"type\":\"object\"}");
    }

    private static String answer(String stopReason, String text) {
        return """
                {"id":"msg_1","type":"message","role":"assistant","model":"claude-test",
                 "content":[{"type":"text","text":%s}],
                 "stop_reason":"%s","usage":{"input_tokens":10,"output_tokens":5}}
                """
                .formatted(quote(text), stopReason);
    }

    private static String quote(String text) {
        return "\"" + text.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    @Test
    void sendsTheRequestTheApiExpectsAndReturnsTheJsonAnswer() {
        server.expect(requestTo("https://api.example.test/v1/messages"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("x-api-key", "secret-key"))
                .andExpect(header("anthropic-version", AnthropicAiClient.API_VERSION))
                .andExpect(jsonPath("$.model").value("claude-test"))
                .andExpect(jsonPath("$.max_tokens").value(2048))
                .andExpect(jsonPath("$.system").value("Be a coach."))
                .andExpect(jsonPath("$.messages[0].role").value("user"))
                .andExpect(jsonPath("$.messages[0].content").value("Correct this."))
                .andExpect(jsonPath("$.output_config.format.type").value("json_schema"))
                .andExpect(jsonPath("$.output_config.format.schema.type").value("object"))
                .andRespond(
                        withSuccess(answer("end_turn", "{\"level\":\"B2\"}"), MediaType.APPLICATION_JSON));

        JsonNode result = client.completeJson("Be a coach.", "Correct this.", schema);

        assertThat(result.path("level").asText()).isEqualTo("B2");
        assertThat(client.model()).isEqualTo("claude-test");
        server.verify();
    }

    @Test
    void aRefusalIsReportedAsSuch() {
        server.expect(requestTo(Matchers.endsWith("/v1/messages")))
                .andRespond(withSuccess(answer("refusal", ""), MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.completeJson("s", "u", schema))
                .isInstanceOf(AiException.class)
                .extracting(e -> ((AiException) e).kind())
                .isEqualTo(AiException.Kind.REFUSED);
    }

    @Test
    void anAnswerCutOffIsInvalid() {
        server.expect(requestTo(Matchers.endsWith("/v1/messages")))
                .andRespond(withSuccess(answer("max_tokens", "{\"lev"), MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.completeJson("s", "u", schema))
                .extracting(e -> ((AiException) e).kind())
                .isEqualTo(AiException.Kind.INVALID_RESPONSE);
    }

    @Test
    void anAnswerThatIsNotJsonIsInvalid() {
        server.expect(requestTo(Matchers.endsWith("/v1/messages")))
                .andRespond(withSuccess(answer("end_turn", "Sure! Here it is."), MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.completeJson("s", "u", schema))
                .extracting(e -> ((AiException) e).kind())
                .isEqualTo(AiException.Kind.INVALID_RESPONSE);
    }

    @Test
    void anErrorFromTheProviderMeansItIsUnavailable() {
        server.expect(requestTo(Matchers.endsWith("/v1/messages"))).andRespond(withServerError());

        assertThatThrownBy(() -> client.completeJson("s", "u", schema))
                .extracting(e -> ((AiException) e).kind())
                .isEqualTo(AiException.Kind.UNAVAILABLE);
    }

    @Test
    void aRejectedKeyMeansItIsUnavailable() {
        server.expect(requestTo(Matchers.endsWith("/v1/messages")))
                .andRespond(withStatus(HttpStatus.UNAUTHORIZED));

        assertThatThrownBy(() -> client.completeJson("s", "u", schema))
                .extracting(e -> ((AiException) e).kind())
                .isEqualTo(AiException.Kind.UNAVAILABLE);
    }
}
