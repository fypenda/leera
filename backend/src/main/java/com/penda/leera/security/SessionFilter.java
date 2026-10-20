package com.penda.leera.security;

import com.penda.leera.account.AccountRepository;
import com.penda.leera.auth.AuthException;
import com.penda.leera.auth.SessionTokens;
import com.penda.leera.error.ApiError;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;
import java.util.UUID;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Lets through only requests with a valid session in {@code Authorization: Bearer}, for an
 * account that still exists, and hands the account's id to the controllers.
 *
 * <p>Everything under {@code /api/} is protected except the health check and signing in
 * (signing in without Apple only exists when {@code leera.auth.dev-sign-in} is on).
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class SessionFilter extends OncePerRequestFilter {

    /** The request attribute holding the signed-in account's {@link UUID}. */
    public static final String ACCOUNT = "leera.account";

    private static final String BEARER = "Bearer ";
    private static final Set<String> OPEN =
            Set.of("/api/v1/health", "/api/v1/auth/apple", "/api/v1/auth/dev");

    private final SessionTokens sessions;
    private final AccountRepository accounts;
    private final ApiErrorWriter errors;

    public SessionFilter(
            SessionTokens sessions, AccountRepository accounts, ApiErrorWriter errors) {
        this.sessions = sessions;
        this.accounts = accounts;
        this.errors = errors;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !isProtected(request);
    }

    static boolean isProtected(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.startsWith("/api/") && !OPEN.contains(path);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        UUID account;
        try {
            String header = request.getHeader(HttpHeaders.AUTHORIZATION);
            if (header == null || !header.startsWith(BEARER)) {
                throw AuthException.unauthorized();
            }
            account = sessions.verify(header.substring(BEARER.length()).strip());
            if (!accounts.exists(account)) {
                throw AuthException.unauthorized();
            }
        } catch (AuthException e) {
            errors.write(response, HttpStatus.UNAUTHORIZED, new ApiError(e.code(), e.getMessage()));
            return;
        }
        request.setAttribute(ACCOUNT, account);
        chain.doFilter(request, response);
    }
}
