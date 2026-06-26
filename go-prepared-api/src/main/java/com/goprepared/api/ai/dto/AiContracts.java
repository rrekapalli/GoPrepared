package com.goprepared.api.ai.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;
import java.util.Map;

public final class AiContracts {
    private AiContracts() {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record JourneyClassification(
            String journeyType,
            String journeySubtype,
            String activity,
            String location,
            String title,
            Double confidence) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record EmergencyContact(String label, String number) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CurrencyInfo(String name, String code, String exchangeRateNote) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CardSection(String title, String body) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CardDetail(
            String heroImageUrl,
            String destinationLabel,
            List<String> dos,
            List<String> donts,
            CurrencyInfo currency,
            String weather,
            List<EmergencyContact> emergencyContacts,
            List<CardSection> sections) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PreparationCard(
            String title,
            String summary,
            String category,
            String icon,
            int displayOrder,
            CardDetail detail) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ChecklistItem(
            String title,
            String description,
            String category,
            int displayOrder,
            boolean completed) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record KnowledgeNode(
            String nodeType,
            String name,
            String description,
            Map<String, Object> metadata) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record KnowledgeEdge(String sourceName, String targetName, String relationshipType) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CommunityInsight(
            String insightType,
            String title,
            String content,
            String journeyContext,
            String severity) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ClassifyResponse(JourneyClassification classification) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record GenerateCardsResponse(List<PreparationCard> cards) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ExpandCardResponse(PreparationCard card) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record UserQueryResponse(String answer) {}
}
