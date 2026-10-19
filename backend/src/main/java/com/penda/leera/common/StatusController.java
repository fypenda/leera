package com.penda.leera.common;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class StatusController {

    /** Open to anyone: says the backend is running, and nothing else. */
    @GetMapping("/health")
    Map<String, String> health() {
        return Map.of("status", "ok");
    }
}
