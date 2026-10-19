package com.penda.nourish.ai;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Asks a language model for an answer shaped by a JSON schema.
 *
 * <p>The rest of the backend depends on this interface only, so the provider can change without
 * touching the features that use it.
 */
public interface AiClient {

    /**
     * Sends {@code system} and {@code user} and returns the model's answer, which follows {@code
     * schema}.
     *
     * @throws AiException if the model cannot be reached, refuses, or answers with something other
     *     than JSON
     */
    JsonNode completeJson(String system, String user, JsonNode schema);

    /** The model that answers, recorded with each result. */
    String model();
}
