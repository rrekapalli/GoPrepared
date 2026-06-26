package com.goprepared.api.ai.workflows;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.goprepared.api.ai.dto.AiContracts.CardDetail;
import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import com.goprepared.api.ai.dto.AiContracts.PreparationCard;
import com.goprepared.api.ai.rag.StaticContentRetrievalService;
import com.goprepared.api.domain.ContentTemplate;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class CardExpansionWorkflow {

    private final Optional<ChatClient.Builder> chatClientBuilder;
    private final StaticContentRetrievalService staticContent;
    private final ObjectMapper objectMapper;

    @Value("${goprepared.ai.fallback-to-static:true}")
    private boolean fallbackToStatic;

    public CardDetail expand(
            JourneyClassification classification, PreparationCard card, String originalQuery) {
        Optional<ContentTemplate> template = staticContent.findBestTemplate(originalQuery);
        if (template.isPresent()) {
            CardDetail fromTemplate = findMatchingDetail(staticContent.cardsFromTemplate(template.get()), card.title());
            if (fromTemplate != null) {
                return fromTemplate;
            }
        }
        if (fallbackToStatic) {
            return defaultDetail(card);
        }
        return expandWithAi(classification, card);
    }

    private CardDetail findMatchingDetail(List<PreparationCard> cards, String title) {
        return cards.stream()
                .filter(c -> c.title().equalsIgnoreCase(title))
                .map(PreparationCard::detail)
                .filter(d -> d != null)
                .findFirst()
                .orElse(null);
    }

    private CardDetail defaultDetail(PreparationCard card) {
        return new CardDetail(
                null,
                card.title(),
                List.of("Review official guidance", "Prepare required documents"),
                List.of("Don't skip safety checks"),
                null,
                "Check local conditions before you go.",
                List.of(),
                List.of());
    }

    private CardDetail expandWithAi(JourneyClassification classification, PreparationCard card) {
        if (chatClientBuilder.isEmpty()) {
            return defaultDetail(card);
        }
        try {
            String prompt = """
                Expand preparation card "%s" for journey %s to structured JSON detail with:
                destinationLabel, dos[], donts[], currency{name,code,exchangeRateNote}, weather, emergencyContacts[].
                Respond with JSON only matching CardDetail fields.
                """
                    .formatted(card.title(), classification.title());

            String response = chatClientBuilder.get().build().prompt(prompt).call().content();
            return objectMapper.readValue(response, CardDetail.class);
        } catch (Exception ex) {
            log.warn("AI card expansion failed: {}", ex.getMessage());
            return defaultDetail(card);
        }
    }
}
