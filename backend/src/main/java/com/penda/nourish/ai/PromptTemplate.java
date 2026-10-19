package com.penda.nourish.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import org.springframework.core.io.ClassPathResource;

/**
 * A versioned prompt and the JSON schema its answer follows, read from {@code
 * prompts/<area>/<version>.md} and {@code prompts/<area>/<version>.schema.json}.
 *
 * <p>A published version never changes: a new wording or a new field is a new version, and the
 * version goes back with each result so the app can tell which prompt produced it.
 */
public record PromptTemplate(String version, String system, JsonNode schema) {

    public static PromptTemplate load(String area, String version, ObjectMapper mapper) {
        String base = "prompts/" + area + "/" + version;
        String system = read(base + ".md");
        try {
            return new PromptTemplate(version, system, mapper.readTree(read(base + ".schema.json")));
        } catch (IOException e) {
            throw new UncheckedIOException("Invalid schema " + base + ".schema.json", e);
        }
    }

    private static String read(String path) {
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Missing resource " + path, e);
        }
    }
}
