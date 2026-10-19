package com.penda.leera.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SessionTokensTest {

    private static final String SECRET = "a-secret-of-more-than-thirty-two-characters";
    private static final Instant NOW = Instant.parse("2026-10-19T10:00:00Z");

    private static SessionTokens at(Instant now, String secret) {
        return new SessionTokens(secret, Duration.ofDays(30), Clock.fixed(now, ZoneOffset.UTC));
    }

    @Test
    void aSessionNamesItsAccountUntilItExpires() {
        UUID account = UUID.randomUUID();
        SessionTokens.Issued issued = at(NOW, SECRET).issue(account);

        assertThat(issued.expiresAt()).isEqualTo(NOW.plus(Duration.ofDays(30)));
        assertThat(at(NOW.plus(Duration.ofDays(29)), SECRET).verify(issued.token()))
                .isEqualTo(account);
        assertThatThrownBy(() -> at(NOW.plus(Duration.ofDays(30)), SECRET).verify(issued.token()))
                .isInstanceOf(AuthException.class);
    }

    @Test
    void aSessionSignedWithAnotherSecretIsRefused() {
        String token = at(NOW, "another-secret-of-more-than-thirty-two-chars").issue(UUID.randomUUID())
                .token();

        assertThatThrownBy(() -> at(NOW, SECRET).verify(token)).isInstanceOf(AuthException.class);
    }

    @Test
    void aTamperedSessionIsRefused() {
        String token = at(NOW, SECRET).issue(UUID.randomUUID()).token();
        String[] parts = token.split("\\.");
        String tampered = parts[0] + "." + parts[1] + "x." + parts[2];

        assertThatThrownBy(() -> at(NOW, SECRET).verify(tampered)).isInstanceOf(AuthException.class);
        assertThatThrownBy(() -> at(NOW, SECRET).verify("garbage")).isInstanceOf(AuthException.class);
    }

    @Test
    void aShortSecretIsRefusedAtOnce() {
        assertThatThrownBy(() -> at(NOW, "short")).isInstanceOf(IllegalArgumentException.class);
    }
}
