package com.penda.leera.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.leera.ai.AiClient;
import com.penda.leera.ai.AnthropicAiClient;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class AiConfiguration {

    @Bean
    AiClient aiClient(RestClient.Builder builder, LeeraProperties properties, ObjectMapper mapper) {
        var anthropic = properties.anthropic();
        var requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(10_000);
        requestFactory.setReadTimeout((int) anthropic.timeout().toMillis());
        return new AnthropicAiClient(builder.requestFactory(requestFactory), anthropic, mapper);
    }

    /** The single source of "now", so tests can pin it. */
    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }
}
