package com.penda.leera.config;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Everything the backend is configured with, from {@code application.yml} and the environment.
 *
 * <p>Secrets come only from environment variables: {@code LEERA_APP_TOKEN} and {@code
 * ANTHROPIC_API_KEY}. The backend refuses to start without them, rather than run unprotected or
 * fail on the first request.
 */
@Validated
@ConfigurationProperties(prefix = "leera")
public record LeeraProperties(
        /* The secret the app sends in the X-App-Token header. */
        @NotBlank String appToken,
        @NotNull @Valid Anthropic anthropic,
        @NotNull @Valid RateLimit rateLimit) {

    public record Anthropic(
            @NotBlank String apiKey,
            @NotBlank String baseUrl,
            @NotBlank String model,
            @Min(256) int maxTokens,
            @NotNull Duration timeout) {}

    /** At most {@code requestsPerHour} authenticated requests per hour, for the whole backend. */
    public record RateLimit(@Min(1) int requestsPerHour) {}
}
