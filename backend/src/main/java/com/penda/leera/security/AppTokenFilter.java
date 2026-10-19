package com.penda.leera.security;

import com.penda.leera.config.LeeraProperties;
import com.penda.leera.error.ApiError;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Lets through only requests that carry the app's secret in {@value #HEADER}.
 *
 * <p>Everything under {@code /api/} is protected except the health check. The comparison takes
 * the same time whatever the token, so it reveals nothing about the right one.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class AppTokenFilter extends OncePerRequestFilter {

    public static final String HEADER = "X-App-Token";

    private final byte[] expected;
    private final ApiErrorWriter errors;

    public AppTokenFilter(LeeraProperties properties, ApiErrorWriter errors) {
        this.expected = properties.appToken().getBytes(StandardCharsets.UTF_8);
        this.errors = errors;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !isProtected(request);
    }

    static boolean isProtected(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.startsWith("/api/") && !path.equals("/api/v1/health");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String given = request.getHeader(HEADER);
        boolean valid =
                given != null
                        && MessageDigest.isEqual(given.getBytes(StandardCharsets.UTF_8), expected);
        if (!valid) {
            errors.write(
                    response,
                    HttpStatus.UNAUTHORIZED,
                    new ApiError("unauthorized", "A valid app token is required."));
            return;
        }
        chain.doFilter(request, response);
    }
}
