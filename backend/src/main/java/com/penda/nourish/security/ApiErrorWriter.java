package com.penda.nourish.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.penda.nourish.error.ApiError;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;

/** Writes an {@link ApiError} from a filter, where no controller advice applies. */
@Component
public class ApiErrorWriter {

    private final ObjectMapper mapper;

    public ApiErrorWriter(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    public void write(HttpServletResponse response, HttpStatus status, ApiError error)
            throws IOException {
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        mapper.writeValue(response.getWriter(), error);
    }
}
