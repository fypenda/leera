package com.penda.nourish.config;

import static org.assertj.core.api.Assertions.assertThat;

import com.penda.nourish.NourishBackendApplication;
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
    @EnableConfigurationProperties(NourishProperties.class)
    static class PropertiesOnly {}

    private final ApplicationContextRunner runner =
            new ApplicationContextRunner()
                    .withConfiguration(
                            AutoConfigurations.of(
                                    ConfigurationPropertiesAutoConfiguration.class,
                                    ValidationAutoConfiguration.class))
                    .withUserConfiguration(PropertiesOnly.class)
                    .withPropertyValues(
                            "nourish.anthropic.base-url=https://api.anthropic.com",
                            "nourish.anthropic.model=claude-test",
                            "nourish.anthropic.max-tokens=1024",
                            "nourish.anthropic.timeout=5s",
                            "nourish.rate-limit.requests-per-hour=10");

    @Test
    void startsWithBothSecrets() {
        runner.withPropertyValues("nourish.app-token=t", "nourish.anthropic.api-key=k")
                .run(context -> assertThat(context).hasNotFailed());
    }

    @Test
    void refusesToStartWithoutTheAppToken() {
        runner.withPropertyValues("nourish.app-token=", "nourish.anthropic.api-key=k")
                .run(context -> assertThat(context).hasFailed());
    }

    @Test
    void refusesToStartWithoutTheApiKey() {
        runner.withPropertyValues("nourish.app-token=t", "nourish.anthropic.api-key=")
                .run(context -> assertThat(context).hasFailed());
    }

    @Test
    void theApplicationClassIsWhereTheScanStarts() {
        assertThat(NourishBackendApplication.class.getPackageName()).isEqualTo("com.penda.nourish");
    }
}
