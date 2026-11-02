package com.scholarsync.dto;

import java.util.List;

public record CareerPathAdminDetail(
        Long id,
        String name,
        String description,
        List<CourseResponse> courses
) {}
