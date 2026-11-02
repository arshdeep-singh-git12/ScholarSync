package com.scholarsync.dto;

public record QuestionResult(
        Long questionId,
        String questionText,
        Long selectedOptionId,
        Long correctOptionId,
        boolean wasCorrect
) {}
