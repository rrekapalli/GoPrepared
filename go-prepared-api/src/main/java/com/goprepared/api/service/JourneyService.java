package com.goprepared.api.service;

import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import com.goprepared.api.ai.dto.AiContracts.PreparationCard;
import com.goprepared.api.ai.dto.AiContracts.UserQueryResponse;
import com.goprepared.api.ai.workflows.*;
import com.goprepared.api.domain.*;
import com.goprepared.api.repository.*;
import com.goprepared.api.web.dto.ApiDtos.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.goprepared.api.ai.dto.AiContracts.CardDetail;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class JourneyService {

    private final JourneyRepository journeyRepository;
    private final CardRepository cardRepository;
    private final CardDetailRepository cardDetailRepository;
    private final JourneyTypeRepository journeyTypeRepository;
    private final JourneySubtypeRepository journeySubtypeRepository;
    private final ActivityRepository activityRepository;
    private final LocationRepository locationRepository;
    private final JourneyClassificationWorkflow classificationWorkflow;
    private final CardGenerationWorkflow cardGenerationWorkflow;
    private final CardExpansionWorkflow cardExpansionWorkflow;
    private final UserQueryWorkflow userQueryWorkflow;
    private final ObjectMapper objectMapper;

    @Transactional
    public JourneyResponse createJourney(User user, String query) {
        JourneyClassification classification = classificationWorkflow.classify(query);
        Journey journey = Journey.builder()
                .user(user)
                .title(classification.title())
                .originalQuery(query)
                .journeyType(resolveType(classification.journeyType()))
                .journeySubtype(resolveSubtype(classification))
                .activity(resolveActivity(classification.activity()))
                .location(resolveLocation(classification.location()))
                .status("DRAFT")
                .progressPercent(0)
                .build();
        journey = journeyRepository.save(journey);
        return toResponse(journey);
    }

    @Transactional
    public GenerateJourneyResponse generateCards(User user, Long journeyId) {
        Journey journey = getOwnedJourney(user, journeyId);
        JourneyClassification classification = classificationWorkflow.classify(journey.getOriginalQuery());
        List<PreparationCard> cards =
                cardGenerationWorkflow.generate(classification, journey.getOriginalQuery());

        cardRepository.findByJourneyOrderByDisplayOrderAsc(journey).forEach(cardRepository::delete);

        for (PreparationCard pc : cards) {
            Card card = Card.builder()
                    .journey(journey)
                    .title(pc.title())
                    .summary(pc.summary())
                    .category(pc.category())
                    .icon(pc.icon())
                    .displayOrder(pc.displayOrder())
                    .viewed(false)
                    .build();
            cardRepository.save(card);
            if (pc.detail() != null) {
                saveDetail(card, pc.detail());
            }
        }
        journey.setStatus("ACTIVE");
        journeyRepository.save(journey);
        return new GenerateJourneyResponse(journey.getId(), cards.size());
    }

    @Transactional(readOnly = true)
    public List<JourneyResponse> listJourneys(User user) {
        return journeyRepository.findByUserOrderByCreatedAtDesc(user).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public JourneyResponse getJourney(User user, Long id) {
        return toResponse(getOwnedJourney(user, id));
    }

    @Transactional(readOnly = true)
    public List<CardResponse> getCards(User user, Long journeyId) {
        Journey journey = getOwnedJourney(user, journeyId);
        return cardRepository.findByJourneyOrderByDisplayOrderAsc(journey).stream()
                .map(this::toCardSummary)
                .toList();
    }

    @Transactional(readOnly = true)
    public AskResponse askJourney(User user, Long journeyId, String question) {
        Journey journey = getOwnedJourney(user, journeyId);
        UserQueryResponse response = userQueryWorkflow.answer(journey, question);
        return new AskResponse(response.answer());
    }

    private void saveDetail(Card card, CardDetail detail) {
        Map<String, Object> content = objectMapper.convertValue(detail, Map.class);
        cardDetailRepository.save(
                CardDetailEntity.builder().card(card).content(content).build());
    }

    private Journey getOwnedJourney(User user, Long id) {
        Journey journey = journeyRepository
                .findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Journey not found"));
        if (!journey.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Journey not found");
        }
        return journey;
    }

    private CardResponse toCardSummary(Card card) {
        return new CardResponse(
                card.getId(),
                card.getTitle(),
                card.getSummary(),
                card.getCategory(),
                card.getIcon(),
                card.getDisplayOrder(),
                card.isViewed(),
                null);
    }

    private JourneyResponse toResponse(Journey journey) {
        return new JourneyResponse(
                journey.getId(),
                journey.getTitle(),
                journey.getOriginalQuery(),
                journey.getStatus(),
                journey.getProgressPercent(),
                journey.getCreatedAt(),
                journey.getJourneyType() != null ? journey.getJourneyType().getName() : null,
                journey.getJourneySubtype() != null ? journey.getJourneySubtype().getName() : null,
                journey.getActivity() != null ? journey.getActivity().getName() : null,
                journey.getLocation() != null ? journey.getLocation().getName() : null);
    }

    private JourneyType resolveType(String name) {
        return journeyTypeRepository
                .findByNameIgnoreCase(name)
                .orElseGet(() -> {
                    JourneyType jt = new JourneyType();
                    jt.setName(name);
                    return journeyTypeRepository.save(jt);
                });
    }

    private JourneySubtype resolveSubtype(JourneyClassification c) {
        JourneyType type = resolveType(c.journeyType());
        return journeySubtypeRepository
                .findByJourneyTypeAndNameIgnoreCase(type, c.journeySubtype())
                .orElseGet(() -> {
                    JourneySubtype st = new JourneySubtype();
                    st.setJourneyType(type);
                    st.setName(c.journeySubtype());
                    return journeySubtypeRepository.save(st);
                });
    }

    private Activity resolveActivity(String name) {
        if (name == null || name.isBlank()) return null;
        return activityRepository
                .findByNameIgnoreCase(name)
                .orElseGet(() -> {
                    Activity a = new Activity();
                    a.setName(name);
                    return activityRepository.save(a);
                });
    }

    private Location resolveLocation(String name) {
        if (name == null || name.isBlank()) return null;
        return locationRepository
                .findByNameIgnoreCase(name)
                .orElseGet(() -> {
                    Location loc = new Location();
                    loc.setName(name);
                    return locationRepository.save(loc);
                });
    }
}
