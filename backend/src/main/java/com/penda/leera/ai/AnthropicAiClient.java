package com.penda.leera.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.leera.config.LeeraProperties;
import java.util.List;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * {@link AiClient} backed by the Claude Messages API, with structured outputs.
 *
 * <p>The API key is sent from here only and never leaves the backend.
 */
public class AnthropicAiClient implements AiClient {

    static final String API_VERSION = "2023-06-01";

    private final RestClient http;
    private final ObjectMapper mapper;
    private final String model;
    private final int maxTokens;

    /**
     * @param builder a builder whose request factory (timeouts) is already set; tests bind a mock
     *     server to it
     */
    public AnthropicAiClient(
            RestClient.Builder builder, LeeraProperties.Anthropic settings, ObjectMapper mapper) {
        this.http =
                builder.baseUrl(settings.baseUrl())
                        .defaultHeader("x-api-key", settings.apiKey())
                        .defaultHeader("anthropic-version", API_VERSION)
                        .build();
        this.mapper = mapper;
        this.model = settings.model();
        this.maxTokens = settings.maxTokens();
    }

    @Override
    public String model() {
        return model;
    }

    @Override
    public JsonNode completeJson(String system, String user, JsonNode schema) {
        Map<String, Object> body =
                Map.of(
                        "model", model,
                        "max_tokens", maxTokens,
                        "system", system,
                        "messages", List.of(Map.of("role", "user", "content", user)),
                        "output_config",
                                Map.of("format", Map.of("type", "json_schema", "schema", schema)));

        JsonNode response;
        try {
            response =
                    http.post()
                            .uri("/v1/messages")
                            .contentType(MediaType.APPLICATION_JSON)
                            .body(body)
                            .retrieve()
                            .body(JsonNode.class);
        } catch (RestClientException e) {
            // The provider's message may describe the request; it is not passed on.
            throw new AiException(AiException.Kind.UNAVAILABLE, "The model could not be reached.", e);
        }
        if (response == null) {
            throw new AiException(AiException.Kind.UNAVAILABLE, "The model sent no answer.");
        }

        String stopReason = response.path("stop_reason").asText("");
        if (stopReason.equals("refusal")) {
            throw new AiException(AiException.Kind.REFUSED, "The model declined to answer.");
        }
        if (stopReason.equals("max_tokens")) {
            throw new AiException(
                    AiException.Kind.INVALID_RESPONSE, "The answer was cut off before its end.");
        }

        for (JsonNode block : response.path("content")) {
            if (block.path("type").asText().equals("text")) {
                try {
                    return mapper.readTree(block.path("text").asText());
                } catch (JsonProcessingException e) {
                    throw new AiException(
                            AiException.Kind.INVALID_RESPONSE, "The answer is not JSON.", e);
                }
            }
        }
        throw new AiException(AiException.Kind.INVALID_RESPONSE, "The answer holds no text.");
    }
}
