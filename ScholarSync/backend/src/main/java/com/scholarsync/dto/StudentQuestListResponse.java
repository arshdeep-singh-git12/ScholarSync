package com.scholarsync.dto;

import java.util.List;

public record StudentQuestListResponse(
        List<SideQuestResponse> quests,
        int totalPointsEarned
) {}
