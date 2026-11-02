package com.scholarsync.dto;

public record CareerPathResponse(
        Long id,
        String name,
        String description,
        int courseCount
) {}
