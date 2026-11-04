package com.penda.leera.account;

import com.penda.leera.auth.AuthException;
import com.penda.leera.auth.SessionTokens;
import com.penda.leera.config.LeeraProperties;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Signs in without Apple, for development before the Apple Developer account exists.
 *
 * <p>Only there when {@code LEERA_DEV_SIGN_IN=true}, and then guarded: with {@code
 * LEERA_DEV_SIGN_IN_TOKEN} set, a request must carry it in {@code X-Leera-Dev-Token}; without it,
 * only a request from this machine is let through. The accounts it makes are named {@code
 * dev:<name>}, cannot be reached with Sign in with Apple, and have no quota while this is on: never
 * turn it on for real users.
 */
@RestController
@RequestMapping("/api/v1/auth")
@ConditionalOnProperty(prefix = "leera.auth", name = "dev-sign-in", havingValue = "true")
public class DevSignInController {

    private static final Logger log = LoggerFactory.getLogger(DevSignInController.class);

    /** What the Apple id of a development account starts with. */
    static final String SUBJECT_PREFIX = "dev:";

    /** @param name a short name for the development account, such as {@code penda} */
    public record DevSignInRequest(@NotBlank @Pattern(regexp = "[a-z0-9-]{1,40}") String name) {}

    /** The header holding {@code LEERA_DEV_SIGN_IN_TOKEN}. */
    static final String TOKEN_HEADER = "X-Leera-Dev-Token";

    private final AccountRepository accounts;
    private final SessionTokens sessions;
    private final QuotaService quotas;

    /** Null without a token: then only this machine may sign in this way. */
    private final byte[] token;

    public DevSignInController(
            AccountRepository accounts,
            SessionTokens sessions,
            QuotaService quotas,
            LeeraProperties properties) {
        this.accounts = accounts;
        this.sessions = sessions;
        this.quotas = quotas;
        String configured = properties.auth().devSignInToken();
        if (configured == null || configured.isBlank()) {
            this.token = null;
            log.warn(
                    "Signing in without Apple is ON (LEERA_DEV_SIGN_IN), from this machine only. "
                            + "Never in production.");
        } else {
            if (configured.length() < 32) {
                throw new IllegalStateException(
                        "LEERA_DEV_SIGN_IN_TOKEN must be 32 characters at least.");
            }
            this.token = configured.getBytes(StandardCharsets.UTF_8);
            log.warn(
                    "Signing in without Apple is ON (LEERA_DEV_SIGN_IN), behind its token. "
                            + "Never for real users.");
        }
    }

    @PostMapping("/dev")
    AccountController.SessionResponse signIn(
            @Valid @RequestBody DevSignInRequest request,
            @RequestHeader(name = TOKEN_HEADER, required = false) String given,
            HttpServletRequest http) {
        if (!allowed(given, http.getRemoteAddr())) throw AuthException.unauthorized();
        Account account = accounts.findOrCreateByAppleSubject(SUBJECT_PREFIX + request.name());
        SessionTokens.Issued session = sessions.issue(account.id());
        return new AccountController.SessionResponse(
                session.token(),
                session.expiresAt(),
                AccountController.QuotaResponse.of(quotas.status(account.id())));
    }

    private boolean allowed(String given, String remoteAddress) {
        if (token == null) return isLoopback(remoteAddress);
        // Compared in constant time, so the answer's timing tells nothing.
        return given != null
                && MessageDigest.isEqual(token, given.getBytes(StandardCharsets.UTF_8));
    }

    /** The address of the client as the server sees it, never a name (no lookup). */
    static boolean isLoopback(String address) {
        if (address == null) return false;
        return address.startsWith("127.")
                || address.equals("::1")
                || address.equals("0:0:0:0:0:0:0:1");
    }
}
