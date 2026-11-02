package com.scholarsync.dto;

import jakarta.validation.constraints.NotNull;

public record CareerPathCourseRequest(
        @NotNull Long courseId,
        int orderIndex
) {}
