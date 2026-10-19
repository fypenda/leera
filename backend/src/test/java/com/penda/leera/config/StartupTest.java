package com.penda.leera.config;

import static org.assertj.core.api.Assertions.assertThat;

import com.penda.leera.LeeraBackendApplication;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.autoconfigure.context.ConfigurationPropertiesAutoConfiguration;
import org.springframework.boot.autoconfigure.validation.ValidationAutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;

/** The backend refuses to start without its secrets, rather than run unprotected. */
class StartupTest {

    @Configuration
    @EnableConfigurationProperties(LeeraProperties.class)
    static class PropertiesOnly {}

    private final ApplicationContextRunner runner =
            new ApplicationContextRunner()
                    .withConfiguration(
                            AutoConfigurations.of(
                                    ConfigurationPropertiesAutoConfiguration.class,
                                    ValidationAutoConfiguration.class))
                    .withUserConfiguration(PropertiesOnly.class)
                    .withPropertyValues(
                            "leera.anthropic.base-url=https://api.anthropic.com",
                            "leera.anthropic.model=claude-test",
                            "leera.anthropic.max-tokens=1024",
                            "leera.anthropic.timeout=5s",
                            "leera.rate-limit.requests-per-hour=10");

    @Test
    void startsWithBothSecrets() {
        runner.withPropertyValues("leera.app-token=t", "leera.anthropic.api-key=k")
                .run(context -> assertThat(context).hasNotFailed());
    }

    @Test
    void refusesToStartWithoutTheAppToken() {
        runner.withPropertyValues("leera.app-token=", "leera.anthropic.api-key=k")
                .run(context -> assertThat(context).hasFailed());
    }

    @Test
    void refusesToStartWithoutTheApiKey() {
        runner.withPropertyValues("leera.app-token=t", "leera.anthropic.api-key=")
                .run(context -> assertThat(context).hasFailed());
    }

    @Test
    void theApplicationClassIsWhereTheScanStarts() {
        assertThat(LeeraBackendApplication.class.getPackageName()).isEqualTo("com.penda.leera");
    }
}
