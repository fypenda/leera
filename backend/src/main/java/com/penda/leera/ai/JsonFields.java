package com.penda.leera.ai;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;

/** Reading a model's answer defensively: anything missing or of the wrong type is empty. */
public final class JsonFields {

    private JsonFields() {}

    /** The text in {@code field}, stripped, or "" if there is none. */
    public static String text(JsonNode node, String field) {
        JsonNode value = node.path(field);
        return value.isTextual() ? value.asText().strip() : "";
    }

    /** The non-blank strings of {@code array}, stripped, at most {@code max} of them. */
    public static List<String> strings(JsonNode array, int max) {
        var result = new ArrayList<String>();
        for (JsonNode item : array) {
            if (result.size() == max) {
                break;
            }
            String value = item.isTextual() ? item.asText().strip() : "";
            if (!value.isEmpty()) {
                result.add(value);
            }
        }
        return List.copyOf(result);
    }

    /** A score from 0 to 10, rounded and kept within bounds, or -1 if it is not a number. */
    public static int score(JsonNode value) {
        if (!value.isNumber()) {
            return -1;
        }
        return Math.max(0, Math.min(10, (int) Math.round(value.asDouble())));
    }
}
