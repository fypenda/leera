package com.penda.leera.error;

import com.penda.leera.account.QuotaExceededException;
import com.penda.leera.account.QuotaService;
import com.penda.leera.ai.AiException;
import com.penda.leera.auth.AuthException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * Turns failures into {@link ApiError} responses with stable codes.
 *
 * <p>Messages never repeat what the person sent: what she writes is personal.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiError> invalid(MethodArgumentNotValidException e) {
        String fields =
                String.join(
                        ", ",
                        e.getBindingResult().getFieldErrors().stream()
                                .map(error -> error.getField())
                                .distinct()
                                .sorted()
                                .toList());
        return respond(
                HttpStatus.BAD_REQUEST,
                "invalid_request",
                "These fields are missing or invalid: " + fields + ".");
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<ApiError> unreadable(HttpMessageNotReadableException e) {
        return respond(HttpStatus.BAD_REQUEST, "invalid_request", "The request is not valid JSON.");
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    ResponseEntity<ApiError> mediaType(HttpMediaTypeNotSupportedException e) {
        return respond(
                HttpStatus.UNSUPPORTED_MEDIA_TYPE, "invalid_request", "Send JSON.");
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    ResponseEntity<ApiError> method(HttpRequestMethodNotSupportedException e) {
        return respond(HttpStatus.METHOD_NOT_ALLOWED, "invalid_request", "Method not allowed.");
    }

    @ExceptionHandler(NoResourceFoundException.class)
    ResponseEntity<ApiError> notFound(NoResourceFoundException e) {
        return respond(HttpStatus.NOT_FOUND, "not_found", "There is nothing here.");
    }

    @ExceptionHandler(AuthException.class)
    ResponseEntity<ApiError> auth(AuthException e) {
        return respond(HttpStatus.UNAUTHORIZED, e.code(), e.getMessage());
    }

    /** The app reads {@code GET /api/v1/me} to say when the quota starts again. */
    @ExceptionHandler(QuotaExceededException.class)
    ResponseEntity<ApiError> quota(QuotaExceededException e) {
        var status = e.status();
        String period = status.plan() == QuotaService.Plan.PLUS
                ? "today"
                : "this week";
        return respond(
                HttpStatus.TOO_MANY_REQUESTS,
                "quota_exceeded",
                "You have used your "
                        + (status.limit() == 1 ? "correction" : status.limit() + " corrections")
                        + " for "
                        + period
                        + ".");
    }

    @ExceptionHandler(AiException.class)
    ResponseEntity<ApiError> ai(AiException e) {
        log.warn("AI request failed: {} ({})", e.getMessage(), e.kind());
        return switch (e.kind()) {
            case UNAVAILABLE ->
                    respond(
                            HttpStatus.BAD_GATEWAY,
                            "ai_unavailable",
                            "The AI service is not available. Try again later.");
            case REFUSED ->
                    respond(
                            HttpStatus.UNPROCESSABLE_ENTITY,
                            "ai_refused",
                            "The AI declined this request.");
            case INVALID_RESPONSE ->
                    respond(
                            HttpStatus.BAD_GATEWAY,
                            "ai_invalid_response",
                            "The AI answer came back incomplete. Try again.");
        };
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiError> unexpected(Exception e) {
        log.error("Unexpected failure", e);
        return respond(
                HttpStatus.INTERNAL_SERVER_ERROR, "internal_error", "Something went wrong.");
    }

    private static ResponseEntity<ApiError> respond(HttpStatus status, String code, String message) {
        return ResponseEntity.status(status).body(new ApiError(code, message));
    }
}
