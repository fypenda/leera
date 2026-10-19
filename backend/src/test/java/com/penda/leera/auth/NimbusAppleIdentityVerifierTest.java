package com.penda.leera.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.List;
import java.util.function.UnaryOperator;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/** Identity tokens signed with a key of the test's own, standing in for Apple's. */
class NimbusAppleIdentityVerifierTest {

    private static final String AUDIENCE = "dev.penda.leera";
    private static final String NONCE = "a-random-nonce";

    private static RSAKey appleKey;
    private static RSAKey otherKey;
    private static NimbusAppleIdentityVerifier verifier;

    @BeforeAll
    static void keys() throws Exception {
        appleKey = new RSAKeyGenerator(2048).keyID("apple-1").generate();
        otherKey = new RSAKeyGenerator(2048).keyID("apple-1").generate();
        verifier = new NimbusAppleIdentityVerifier(
                new ImmutableJWKSet<SecurityContext>(new JWKSet(appleKey.toPublicJWK())),
                List.of(AUDIENCE));
    }

    private static String token(RSAKey key, UnaryOperator<JWTClaimsSet.Builder> change)
            throws Exception {
        Instant now = Instant.now();
        var claims = new JWTClaimsSet.Builder()
                .issuer(NimbusAppleIdentityVerifier.ISSUER)
                .audience(AUDIENCE)
                .subject("001234.abcdef.0987")
                .issueTime(Date.from(now))
                .expirationTime(Date.from(now.plus(10, ChronoUnit.MINUTES)))
                .claim("nonce", NimbusAppleIdentityVerifier.sha256Hex(NONCE));
        var jwt = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256).keyID(key.getKeyID()).build(),
                change.apply(claims).build());
        jwt.sign(new RSASSASigner(key));
        return jwt.serialize();
    }

    private static void refused(String token, String nonce) {
        assertThatThrownBy(() -> verifier.verify(token, nonce))
                .isInstanceOfSatisfying(
                        AuthException.class, e -> assertThat(e.code()).isEqualTo("invalid_identity"));
    }

    @Test
    void aGoodTokenGivesTheAppleUserId() throws Exception {
        assertThat(verifier.verify(token(appleKey, c -> c), NONCE)).isEqualTo("001234.abcdef.0987");
    }

    @Test
    void theNonceMustBeTheOneTheAppChose() throws Exception {
        refused(token(appleKey, c -> c), "another-nonce");
        refused(token(appleKey, c -> c.claim("nonce", null)), NONCE);
    }

    @Test
    void theTokenMustBeForThisApp() throws Exception {
        refused(token(appleKey, c -> c.audience("com.someone.else")), NONCE);
    }

    @Test
    void theTokenMustComeFromApple() throws Exception {
        refused(token(appleKey, c -> c.issuer("https://example.com")), NONCE);
        refused(token(otherKey, c -> c), NONCE);
    }

    @Test
    void anExpiredTokenIsRefused() throws Exception {
        Instant past = Instant.now().minus(2, ChronoUnit.HOURS);
        refused(
                token(appleKey, c -> c.issueTime(Date.from(past))
                        .expirationTime(Date.from(past.plus(10, ChronoUnit.MINUTES)))),
                NONCE);
    }

    @Test
    void somethingThatIsNotATokenIsRefused() {
        refused("not a token", NONCE);
    }
}
