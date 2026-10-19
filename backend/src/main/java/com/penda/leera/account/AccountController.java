package com.penda.leera.account;

import com.penda.leera.auth.AppleIdentityVerifier;
import com.penda.leera.auth.SessionTokens;
import com.penda.leera.security.SessionFilter;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Signing in with Apple, the account's quota, and deleting the account. */
@RestController
@RequestMapping("/api/v1")
public class AccountController {

    /**
     * @param identityToken the identity token Sign in with Apple gave the app
     * @param nonce the raw nonce the app generated (Apple's token holds its SHA-256)
     */
    public record AppleSignInRequest(@NotBlank String identityToken, @NotBlank String nonce) {}

    /** Where the account stands. {@code plan} is {@code free} or {@code plus}. */
    public record QuotaResponse(String plan, int used, int limit, Instant resetsAt) {

        static QuotaResponse of(QuotaService.Status status) {
            return new QuotaResponse(
                    status.plan().name().toLowerCase(Locale.ROOT),
                    status.used(),
                    status.limit(),
                    status.resetsAt());
        }
    }

    public record SessionResponse(String accessToken, Instant expiresAt, QuotaResponse quota) {}

    public record MeResponse(QuotaResponse quota) {}

    private final AppleIdentityVerifier apple;
    private final AccountRepository accounts;
    private final SessionTokens sessions;
    private final QuotaService quotas;

    public AccountController(
            AppleIdentityVerifier apple,
            AccountRepository accounts,
            SessionTokens sessions,
            QuotaService quotas) {
        this.apple = apple;
        this.accounts = accounts;
        this.sessions = sessions;
        this.quotas = quotas;
    }

    /** Signs in, creating the account the first time. Open to anyone. */
    @PostMapping("/auth/apple")
    SessionResponse signIn(@Valid @RequestBody AppleSignInRequest request) {
        String subject = apple.verify(request.identityToken(), request.nonce());
        Account account = accounts.findOrCreateByAppleSubject(subject);
        SessionTokens.Issued session = sessions.issue(account.id());
        return new SessionResponse(
                session.token(),
                session.expiresAt(),
                QuotaResponse.of(quotas.status(account.id())));
    }

    @GetMapping("/me")
    MeResponse me(@RequestAttribute(SessionFilter.ACCOUNT) UUID account) {
        return new MeResponse(QuotaResponse.of(quotas.status(account)));
    }

    /**
     * Deletes the account and everything the backend holds about it. Its sessions stop working
     * at once.
     */
    @DeleteMapping("/account")
    ResponseEntity<Void> delete(@RequestAttribute(SessionFilter.ACCOUNT) UUID account) {
        accounts.delete(account);
        return ResponseEntity.noContent().build();
    }
}
