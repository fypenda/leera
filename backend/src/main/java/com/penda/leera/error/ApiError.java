package com.penda.leera.error;

/**
 * The body of every error response. {@code code} is stable and meant for the app; {@code
 * message} is for people.
 */
public record ApiError(String code, String message) {}
