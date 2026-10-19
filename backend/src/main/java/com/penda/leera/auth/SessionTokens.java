package com.penda.leera.auth;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.nio.charset.StandardCharsets;
import java.text.ParseException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

/**
 * The app's sessions: a JWT signed with HMAC-SHA256, naming the account and when it expires.
 *
 * <p>Stateless: nothing is stored. Deleting an account ends its sessions, because every request
 * checks that the account still exists.
 */
public class SessionTokens {

    static final String ISSUER = "leera";

    /** A session handed to the app. */
    public record Issued(String token, Instant expiresAt) {}

    private final byte[] secret;
    private final Duration lifetime;
    private final Clock clock;

    public SessionTokens(String secret, Duration lifetime, Clock clock) {
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        if (this.secret.length < 32) {
            throw new IllegalArgumentException("The session secret needs 32 bytes at least.");
        }
        this.lifetime = lifetime;
        this.clock = clock;
    }

    public Issued issue(UUID accountId) {
        Instant now = clock.instant();
        Instant expiresAt = now.plus(lifetime);
        var claims =
                new JWTClaimsSet.Builder()
                        .issuer(ISSUER)
                        .subject(accountId.toString())
                        .issueTime(Date.from(now))
                        .expirationTime(Date.from(expiresAt))
                        .build();
        var jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
        try {
            jwt.sign(new MACSigner(secret));
        } catch (JOSEException e) {
            throw new IllegalStateException("The session could not be signed.", e);
        }
        return new Issued(jwt.serialize(), expiresAt);
    }

    /** The account of a valid session, or {@link AuthException#unauthorized()}. */
    public UUID verify(String token) {
        try {
            SignedJWT jwt = SignedJWT.parse(token);
            if (!JWSAlgorithm.HS256.equals(jwt.getHeader().getAlgorithm())
                    || !jwt.verify(new MACVerifier(secret))) {
                throw AuthException.unauthorized();
            }
            JWTClaimsSet claims = jwt.getJWTClaimsSet();
            Date expiresAt = claims.getExpirationTime();
            if (!ISSUER.equals(claims.getIssuer())
                    || expiresAt == null
                    || !clock.instant().isBefore(expiresAt.toInstant())
                    || claims.getSubject() == null) {
                throw AuthException.unauthorized();
            }
            return UUID.fromString(claims.getSubject());
        } catch (ParseException | JOSEException | IllegalArgumentException e) {
            throw AuthException.unauthorized();
        }
    }
}
