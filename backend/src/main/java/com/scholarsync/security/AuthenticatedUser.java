package com.scholarsync.security;

/** The principal placed into the SecurityContext after a valid JWT is parsed. */
public record AuthenticatedUser(Long userId, String username, String role) {}
