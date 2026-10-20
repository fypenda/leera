package com.penda.leera.account;

import com.penda.leera.auth.SessionTokens;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Signs in without Apple, for development before the Apple Developer account exists.
 *
 * <p>Only there when {@code LEERA_DEV_SIGN_IN=true}: anyone who can reach the backend could then
 * open any development account. Never turn it on in production. The accounts it makes are named
 * {@code dev:<name>} and cannot be reached with Sign in with Apple.
 */
@RestController
@RequestMapping("/api/v1/auth")
@ConditionalOnProperty(prefix = "leera.auth", name = "dev-sign-in", havingValue = "true")
public class DevSignInController {

    private static final Logger log = LoggerFactory.getLogger(DevSignInController.class);

    /** @param name a short name for the development account, such as {@code penda} */
    public record DevSignInRequest(@NotBlank @Pattern(regexp = "[a-z0-9-]{1,40}") String name) {}

    private final AccountRepository accounts;
    private final SessionTokens sessions;
    private final QuotaService quotas;

    public DevSignInController(
            AccountRepository accounts, SessionTokens sessions, QuotaService quotas) {
        this.accounts = accounts;
        this.sessions = sessions;
        this.quotas = quotas;
        log.warn("Signing in without Apple is ON (LEERA_DEV_SIGN_IN). Never in production.");
    }

    @PostMapping("/dev")
    AccountController.SessionResponse signIn(@Valid @RequestBody DevSignInRequest request) {
        Account account = accounts.findOrCreateByAppleSubject("dev:" + request.name());
        SessionTokens.Issued session = sessions.issue(account.id());
        return new AccountController.SessionResponse(
                session.token(),
                session.expiresAt(),
                AccountController.QuotaResponse.of(quotas.status(account.id())));
    }
}
