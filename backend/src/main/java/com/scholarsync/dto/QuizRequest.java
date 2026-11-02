package com.scholarsync.dto;

import jakarta.validation.constraints.NotBlank;

public record QuizRequest(
        @NotBlank String title,
        String description
) {}
