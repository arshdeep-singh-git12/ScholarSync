package com.scholarsync.dto;

public record StudentPerformance(
        Long studentId,
        String studentName,
        CourseProgressResponse progress
) {}
