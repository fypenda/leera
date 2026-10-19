package com.penda.leera.config;

import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.JWKSourceBuilder;
import com.nimbusds.jose.proc.SecurityContext;
import com.penda.leera.auth.AppleIdentityVerifier;
import com.penda.leera.auth.NimbusAppleIdentityVerifier;
import com.penda.leera.auth.SessionTokens;
import java.net.MalformedURLException;
import java.net.URI;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AuthConfiguration {

    /** Apple's keys are fetched on first use, then cached and refreshed by Nimbus. */
    @Bean
    AppleIdentityVerifier appleIdentityVerifier(LeeraProperties properties)
            throws MalformedURLException {
        var auth = properties.auth();
        JWKSource<SecurityContext> keys =
                JWKSourceBuilder.<SecurityContext>create(URI.create(auth.appleKeysUrl()).toURL())
                        .build();
        return new NimbusAppleIdentityVerifier(keys, auth.appleAudiences());
    }

    @Bean
    SessionTokens sessionTokens(LeeraProperties properties, Clock clock) {
        var auth = properties.auth();
        return new SessionTokens(auth.sessionSecret(), auth.sessionLifetime(), clock);
    }
}
