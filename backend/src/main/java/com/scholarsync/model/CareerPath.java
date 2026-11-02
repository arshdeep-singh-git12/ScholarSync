package com.scholarsync.model;

import java.time.LocalDateTime;

public record CareerPath(
        Long id,
        String name,
        String description,
        LocalDateTime createdAt
) {}
