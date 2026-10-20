package com.penda.leera.config;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Everything the backend is configured with, from {@code application.yml} and the environment.
 *
 * <p>Secrets come only from environment variables: {@code ANTHROPIC_API_KEY} and {@code
 * LEERA_SESSION_SECRET}. The backend refuses to start without them, rather than run unprotected
 * or fail on the first request.
 */
@Validated
@ConfigurationProperties(prefix = "leera")
public record LeeraProperties(
        @NotNull @Valid Anthropic anthropic,
        @NotNull @Valid RateLimit rateLimit,
        @NotNull @Valid Auth auth,
        @NotNull @Valid Quota quota) {

    public record Anthropic(
            @NotBlank String apiKey,
            @NotBlank String baseUrl,
            @NotBlank String model,
            @Min(256) int maxTokens,
            @NotNull Duration timeout) {}

    /** At most {@code requestsPerHour} authenticated requests per hour, for the whole backend. */
    public record RateLimit(@Min(1) int requestsPerHour) {}

    /**
     * Sign in with Apple and the app's own sessions.
     *
     * @param sessionSecret signs the sessions (HMAC-SHA256): 32 characters at least
     * @param sessionLifetime how long a session lasts before the app must sign in again
     * @param appleAudiences the bundle ids Apple's identity tokens may be issued for
     * @param appleKeysUrl where Apple publishes the keys that sign its identity tokens
     * @param devSignIn opens {@code POST /api/v1/auth/dev}, which signs in without Apple. For a
     *     backend on the developer's own machine only, never in production.
     */
    public record Auth(
            @NotBlank @Size(min = 32) String sessionSecret,
            @NotNull Duration sessionLifetime,
            @NotEmpty List<@NotBlank String> appleAudiences,
            @NotBlank String appleKeysUrl,
            boolean devSignIn) {}

    /**
     * How many corrections an account may ask for: per week (Monday to Sunday, UTC) on the free
     * plan, per day (UTC) on Leera Plus.
     */
    public record Quota(@Min(0) int freePerWeek, @Min(1) int plusPerDay) {}
}
