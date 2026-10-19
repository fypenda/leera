package com.penda.leera.auth;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.BadJOSEException;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTClaimsVerifier;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.ParseException;
import java.util.Collection;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Set;

/**
 * Verifies Apple identity tokens: signed by one of Apple's published keys (RS256), issued by
 * Apple, for one of this app's bundle ids, not expired, and carrying the nonce the app chose.
 */
public class NimbusAppleIdentityVerifier implements AppleIdentityVerifier {

    static final String ISSUER = "https://appleid.apple.com";

    private final ConfigurableJWTProcessor<SecurityContext> processor;

    /**
     * @param keys Apple's public keys (in production, fetched and cached from Apple)
     * @param audiences the bundle ids accepted
     */
    public NimbusAppleIdentityVerifier(
            JWKSource<SecurityContext> keys, Collection<String> audiences) {
        var processor = new DefaultJWTProcessor<SecurityContext>();
        processor.setJWSKeySelector(new JWSVerificationKeySelector<>(JWSAlgorithm.RS256, keys));
        processor.setJWTClaimsSetVerifier(
                new DefaultJWTClaimsVerifier<>(
                        new HashSet<>(audiences),
                        new JWTClaimsSet.Builder().issuer(ISSUER).build(),
                        Set.of("sub", "exp", "iat", "nonce"),
                        null));
        this.processor = processor;
    }

    @Override
    public String verify(String identityToken, String rawNonce) {
        JWTClaimsSet claims;
        String nonce;
        try {
            claims = processor.process(identityToken, null);
            nonce = claims.getStringClaim("nonce");
        } catch (ParseException | BadJOSEException | JOSEException e) {
            throw AuthException.invalidIdentity();
        }
        byte[] expected = sha256Hex(rawNonce).getBytes(StandardCharsets.UTF_8);
        if (nonce == null
                || !MessageDigest.isEqual(nonce.getBytes(StandardCharsets.UTF_8), expected)) {
            throw AuthException.invalidIdentity();
        }
        String subject = claims.getSubject();
        if (subject == null || subject.isBlank()) {
            throw AuthException.invalidIdentity();
        }
        return subject;
    }

    static String sha256Hex(String value) {
        try {
            byte[] digest =
                    MessageDigest.getInstance("SHA-256")
                            .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is always available.", e);
        }
    }
}
