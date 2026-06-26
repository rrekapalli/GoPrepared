package com.goprepared.api.ai.rag;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import com.goprepared.api.ai.dto.AiContracts.PreparationCard;
import com.goprepared.api.domain.ContentTemplate;
import com.goprepared.api.repository.ContentTemplateRepository;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class StaticContentRetrievalService {

    private final ContentTemplateRepository contentTemplateRepository;
    private final ObjectMapper objectMapper;

    public Optional<ContentTemplate> findBestTemplate(String query) {
        String q = query.toLowerCase(Locale.ROOT).trim();
        if (q.isEmpty()) {
            return contentTemplateRepository.findAll().stream().findFirst();
        }

        return contentTemplateRepository.findAll().stream()
                .map(t -> Map.entry(t, scoreTemplate(t, q)))
                .filter(entry -> entry.getValue() > 0)
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey);
    }

    private int scoreTemplate(ContentTemplate template, String query) {
        int score = 0;
        String key = safeLower(template.getTemplateKey());
        String location = safeLower(template.getLocation());
        String activity = safeLower(template.getActivity());
        String journeyType = safeLower(template.getJourneyType());
        String title = extractTitle(template);

        if (!key.isEmpty() && query.contains(key.replace("-", " "))) {
            score += 100;
        }
        if (!location.isEmpty() && query.contains(location)) {
            score += 80;
        }
        if (!activity.isEmpty() && query.contains(activity)) {
            score += 70;
        }
        if (!title.isEmpty() && query.contains(title)) {
            score += 60;
        }
        if (!journeyType.isEmpty() && query.contains(journeyType)) {
            score += 20;
        }

        for (String token : query.split("\\s+")) {
            if (token.length() < 3) {
                continue;
            }
            if (key.contains(token)) {
                score += 15;
            }
            if (location.contains(token)) {
                score += 12;
            }
            if (activity.contains(token)) {
                score += 10;
            }
            if (title.contains(token)) {
                score += 8;
            }
        }
        return score;
    }

    private String extractTitle(ContentTemplate template) {
        Map<String, Object> payload = template.getPayload();
        if (payload == null) {
            return "";
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> classification = (Map<String, Object>) payload.get("classification");
        if (classification == null) {
            return "";
        }
        Object title = classification.get("title");
        return title != null ? title.toString().toLowerCase(Locale.ROOT) : "";
    }

    private String safeLower(String value) {
        return value != null ? value.toLowerCase(Locale.ROOT) : "";
    }

    public JourneyClassification classificationFromTemplate(ContentTemplate template) {
        Map<String, Object> payload = template.getPayload();
        @SuppressWarnings("unchecked")
        Map<String, Object> classification = (Map<String, Object>) payload.get("classification");
        return objectMapper.convertValue(classification, JourneyClassification.class);
    }

    public List<PreparationCard> cardsFromTemplate(ContentTemplate template) {
        Map<String, Object> payload = template.getPayload();
        Object cards = payload.get("cards");
        if (cards == null) {
            return Collections.emptyList();
        }
        return objectMapper.convertValue(cards, new TypeReference<List<PreparationCard>>() {});
    }

    public String buildContextSnippet(ContentTemplate template) {
        return template.getTemplateKey() + " | "
                + template.getJourneyType() + " / "
                + template.getJourneySubtype() + " / "
                + template.getLocation();
    }
}
