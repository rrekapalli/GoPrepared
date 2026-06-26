package com.goprepared.api.ai.workflows;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.goprepared.api.ai.dto.AiContracts.GenerateCardsResponse;
import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import com.goprepared.api.ai.dto.AiContracts.PreparationCard;
import com.goprepared.api.ai.rag.StaticContentRetrievalService;
import com.goprepared.api.domain.ContentTemplate;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class CardGenerationWorkflow {

    private final Optional<ChatClient.Builder> chatClientBuilder;
    private final StaticContentRetrievalService staticContent;
    private final ObjectMapper objectMapper;

    @Value("${goprepared.ai.fallback-to-static:true}")
    private boolean fallbackToStatic;

    public List<PreparationCard> generate(JourneyClassification classification, String originalQuery) {
        Optional<ContentTemplate> template = staticContent.findBestTemplate(originalQuery);
        if (fallbackToStatic && template.isPresent()) {
            List<PreparationCard> cards = staticContent.cardsFromTemplate(template.get());
            if (!cards.isEmpty()) {
                return cards;
            }
        }
        return generateWithAi(classification, template.orElse(null));
    }

    private List<PreparationCard> generateWithAi(JourneyClassification classification, ContentTemplate template) {
        if (chatClientBuilder.isEmpty()) {
            return template != null ? staticContent.cardsFromTemplate(template) : List.of();
        }
        try {
            String context = template != null ? staticContent.buildContextSnippet(template) : "";
            String prompt = """
                Generate 8 preparation cards as JSON array under key "cards".
                Each card: title, summary, category, icon, displayOrder.
                Journey: %s / %s / %s
                Context: %s
                Respond with JSON only: {"cards":[...]}
                """
                    .formatted(
                            classification.journeyType(),
                            classification.journeySubtype(),
                            classification.location(),
                            context);

            String response = chatClientBuilder.get().build().prompt(prompt).call().content();
            GenerateCardsResponse parsed = objectMapper.readValue(response, GenerateCardsResponse.class);
            return parsed.cards();
        } catch (Exception ex) {
            log.warn("AI card generation failed: {}", ex.getMessage());
            if (template != null) {
                return staticContent.cardsFromTemplate(template);
            }
            return List.of();
        }
    }
}
