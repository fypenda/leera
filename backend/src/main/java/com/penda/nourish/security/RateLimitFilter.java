package com.penda.nourish.security;

import com.penda.nourish.config.NourishProperties;
import com.penda.nourish.error.ApiError;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Caps authenticated requests per hour, for the whole backend.
 *
 * <p>There is one user, so one counter. It is a ceiling on the AI bill if the app token ever
 * leaks, not a fairness mechanism. It runs after {@link AppTokenFilter}, so refused requests do
 * not use it up. The count is kept in memory and starts again when the backend restarts.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Duration WINDOW = Duration.ofHours(1);

    private final int limit;
    private final Clock clock;
    private final ApiErrorWriter errors;

    private Instant windowStart = Instant.EPOCH;
    private int used;

    public RateLimitFilter(NourishProperties properties, Clock clock, ApiErrorWriter errors) {
        this.limit = properties.rateLimit().requestsPerHour();
        this.clock = clock;
        this.errors = errors;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !AppTokenFilter.isProtected(request);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        if (!tryAcquire()) {
            response.setHeader("Retry-After", String.valueOf(WINDOW.toSeconds()));
            errors.write(
                    response,
                    HttpStatus.TOO_MANY_REQUESTS,
                    new ApiError("rate_limited", "Too many requests. Try again later."));
            return;
        }
        chain.doFilter(request, response);
    }

    private synchronized boolean tryAcquire() {
        Instant now = clock.instant();
        if (!now.isBefore(windowStart.plus(WINDOW))) {
            windowStart = now;
            used = 0;
        }
        if (used >= limit) {
            return false;
        }
        used++;
        return true;
    }
}
