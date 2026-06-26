package com.goprepared.api.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.goprepared.api.ai.dto.AiContracts.CardDetail;
import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import com.goprepared.api.ai.dto.AiContracts.PreparationCard;
import com.goprepared.api.ai.dto.AiContracts.UserQueryResponse;
import com.goprepared.api.ai.workflows.CardExpansionWorkflow;
import com.goprepared.api.ai.workflows.JourneyClassificationWorkflow;
import com.goprepared.api.ai.workflows.UserQueryWorkflow;
import com.goprepared.api.domain.Card;
import com.goprepared.api.domain.CardDetailEntity;
import com.goprepared.api.domain.Journey;
import com.goprepared.api.domain.User;
import com.goprepared.api.repository.CardDetailRepository;
import com.goprepared.api.repository.CardRepository;
import com.goprepared.api.repository.JourneyRepository;
import com.goprepared.api.web.dto.ApiDtos.AskResponse;
import com.goprepared.api.web.dto.ApiDtos.CardResponse;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CardService {

    private final CardRepository cardRepository;
    private final CardDetailRepository cardDetailRepository;
    private final JourneyRepository journeyRepository;
    private final JourneyClassificationWorkflow classificationWorkflow;
    private final CardExpansionWorkflow cardExpansionWorkflow;
    private final UserQueryWorkflow userQueryWorkflow;
    private final ObjectMapper objectMapper;

    @Transactional
    public CardResponse getCard(User user, Long cardId) {
        Card card = getOwnedCard(user, cardId);
        card.setViewed(true);
        cardRepository.save(card);

        if (cardDetailRepository.findByCard(card).isEmpty()) {
            expandCard(card);
        }
        updateJourneyProgress(card.getJourney());
        return toResponse(card);
    }

    @Transactional(readOnly = true)
    public AskResponse askCard(User user, Long cardId, String question) {
        Card card = getOwnedCard(user, cardId);
        Journey journey = card.getJourney();
        String contextualQuestion = "About the preparation card '%s' (%s): %s"
                .formatted(card.getTitle(), card.getCategory(), question);
        UserQueryResponse response = userQueryWorkflow.answer(journey, contextualQuestion);
        return new AskResponse(response.answer());
    }

    private void expandCard(Card card) {
        Journey journey = card.getJourney();
        JourneyClassification classification = classificationWorkflow.classify(journey.getOriginalQuery());
        PreparationCard prep = new PreparationCard(
                card.getTitle(),
                card.getSummary(),
                card.getCategory(),
                card.getIcon(),
                card.getDisplayOrder(),
                null);
        CardDetail expanded = cardExpansionWorkflow.expand(classification, prep, journey.getOriginalQuery());
        Map<String, Object> content = objectMapper.convertValue(expanded, Map.class);
        cardDetailRepository.save(
                CardDetailEntity.builder().card(card).content(content).build());
    }

    private void updateJourneyProgress(Journey journey) {
        List<Card> cards = cardRepository.findByJourneyOrderByDisplayOrderAsc(journey);
        if (cards.isEmpty()) return;
        long viewed = cards.stream().filter(Card::isViewed).count();
        journey.setProgressPercent((int) (viewed * 100 / cards.size()));
        journeyRepository.save(journey);
    }

    private Card getOwnedCard(User user, Long cardId) {
        Card card = cardRepository
                .findById(cardId)
                .orElseThrow(() -> new EntityNotFoundException("Card not found"));
        if (!card.getJourney().getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Card not found");
        }
        return card;
    }

    private CardResponse toResponse(Card card) {
        Map<String, Object> detail = cardDetailRepository
                .findByCard(card)
                .map(CardDetailEntity::getContent)
                .orElse(null);
        return new CardResponse(
                card.getId(),
                card.getTitle(),
                card.getSummary(),
                card.getCategory(),
                card.getIcon(),
                card.getDisplayOrder(),
                card.isViewed(),
                detail);
    }
}
