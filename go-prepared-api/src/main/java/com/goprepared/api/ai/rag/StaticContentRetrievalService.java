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
        String q = query.toLowerCase(Locale.ROOT);
        if (q.contains("bali")) {
            return contentTemplateRepository.findByTemplateKey("bali-vacation");
        }
        if (q.contains("vizag") || q.contains("10k")) {
            return contentTemplateRepository.findByTemplateKey("vizag-10k");
        }
        if (q.contains("angiogram")) {
            return contentTemplateRepository.findByTemplateKey("angiogram");
        }
        return contentTemplateRepository.findAll().stream().findFirst();
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
