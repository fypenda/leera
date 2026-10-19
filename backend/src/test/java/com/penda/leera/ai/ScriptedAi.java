package com.penda.leera.ai;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;

/** Answers with what it is given, in order, and remembers what it was asked. */
public final class ScriptedAi implements AiClient {

    public final Deque<Object> answers = new ArrayDeque<>();
    public final List<String> systems = new ArrayList<>();
    public final List<String> users = new ArrayList<>();
    public final List<JsonNode> schemas = new ArrayList<>();

    @Override
    public JsonNode completeJson(String system, String user, JsonNode schema) {
        systems.add(system);
        users.add(user);
        schemas.add(schema);
        Object next = answers.removeFirst();
        if (next instanceof AiException e) {
            throw e;
        }
        return (JsonNode) next;
    }

    @Override
    public String model() {
        return "claude-test";
    }
}
