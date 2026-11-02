package com.scholarsync.model;

public record QuizQuestion(
        Long id,
        Long quizId,
        String questionText,
        int orderIndex
) {}
