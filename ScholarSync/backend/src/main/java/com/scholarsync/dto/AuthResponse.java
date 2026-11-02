package com.scholarsync.dto;

public record AuthResponse(
        String token,
        Long userId,
        String username,
        String fullName,
        String role
) {}
