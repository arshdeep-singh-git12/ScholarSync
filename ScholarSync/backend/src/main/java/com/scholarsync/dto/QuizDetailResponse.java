package com.scholarsync.dto;

import java.util.List;

public record QuizDetailResponse(
        Long id,
        Long courseId,
        String title,
        String description,
        List<QuestionResponse> questions
) {}
