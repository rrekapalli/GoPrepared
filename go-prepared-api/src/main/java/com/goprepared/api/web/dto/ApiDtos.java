package com.goprepared.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.Map;

public final class ApiDtos {
    private ApiDtos() {}

    public record AuthResponse(String accessToken, UserResponse user) {}

    public record OAuthConfigResponse(
            String googleClientId, String microsoftClientId, String microsoftTenantId, String microsoftRedirectUri) {}

    public record GoogleAuthRequest(@NotBlank String idToken) {}

    public record MicrosoftAuthRequest(@NotBlank String idToken) {}

    public record DevAuthRequest(@NotBlank String email, String name) {}

    public record UserResponse(Long id, String name, String email, String profilePicture) {}

    public record CreateJourneyRequest(@NotBlank String query) {}

    public record JourneyResponse(
            Long id,
            String title,
            String originalQuery,
            String status,
            int progressPercent,
            Instant createdAt,
            String journeyType,
            String journeySubtype,
            String activity,
            String location) {}

    public record JourneyStatusResponse(
            Long journeyId,
            String status,
            int progressPercent,
            int cardsCompleted,
            int cardsTotal,
            int checklistCompleted,
            int checklistTotal) {}

    public record CardResponse(
            Long id,
            String title,
            String summary,
            String category,
            String icon,
            int displayOrder,
            boolean viewed,
            Map<String, Object> detail) {}

    public record AskRequest(@NotBlank String question) {}

    public record AskResponse(String answer) {}

    public record GenerateJourneyResponse(Long journeyId, int cardCount) {}

    public record ChecklistItemResponse(
            Long id, String title, String description, String category, int displayOrder, boolean completed, boolean userAdded) {}

    public record AddChecklistItemRequest(
            @NotBlank String title, String description, String category) {}

    public record ChecklistResponse(
            Long journeyId, String title, int completionPercent, List<ChecklistItemResponse> items) {}

    public record KnowledgeCategoryResponse(String name, String icon, int journeyCount) {}

    public record KnowledgeNodeResponse(String nodeType, String name, String description) {}

    public record KnowledgeEdgeResponse(String sourceName, String targetName, String relationshipType) {}

    public record KnowledgeTemplateResponse(
            String templateKey,
            String title,
            String journeyType,
            String journeySubtype,
            String activity,
            String location,
            String suggestedQuery) {}

    public record SimilarJourneyResponse(
            Long id, String title, String originalQuery, String source, int progressPercent) {}

    public record CommunityInsightResponse(
            Long id,
            String insightType,
            String title,
            String content,
            String journeyContext,
            String severity,
            int votes) {}

    public record ContributeInsightRequest(
            @NotBlank String insightType,
            @NotBlank String title,
            @NotBlank String content,
            String journeyContext,
            String severity,
            Long journeyId) {}

    public record VoteInsightRequest(@NotNull Long insightId, boolean helpful) {}

    public record VoteInsightResponse(Long insightId, int votes, boolean helpful) {}

    public record ErrorResponse(String error, String message, Instant timestamp) {}
}
