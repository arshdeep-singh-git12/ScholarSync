package com.scholarsync.dto;

public record QuizAttemptSummary(
        Long attemptId,
        int score,
        int totalQuestions,
        String submittedAt
) {}
