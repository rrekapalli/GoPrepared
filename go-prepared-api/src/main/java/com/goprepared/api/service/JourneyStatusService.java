package com.goprepared.api.service;

import com.goprepared.api.domain.*;
import com.goprepared.api.repository.*;
import com.goprepared.api.web.dto.ApiDtos.JourneyStatusResponse;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class JourneyStatusService {

    private final JourneyRepository journeyRepository;
    private final CardRepository cardRepository;
    private final ChecklistItemRepository checklistItemRepository;

    @Transactional(readOnly = true)
    public JourneyStatusResponse getStatus(User user, Long journeyId) {
        Journey journey = journeyRepository
                .findById(journeyId)
                .orElseThrow(() -> new EntityNotFoundException("Journey not found"));
        if (!journey.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Journey not found");
        }
        var cards = cardRepository.findByJourneyOrderByDisplayOrderAsc(journey);
        long cardsViewed = cards.stream().filter(Card::isViewed).count();
        long checklistTotal = checklistItemRepository.countByJourney(journey);
        long checklistDone = checklistItemRepository.countByJourneyAndCompletedTrue(journey);

        return new JourneyStatusResponse(
                journey.getId(),
                journey.getStatus(),
                journey.getProgressPercent(),
                (int) cardsViewed,
                cards.size(),
                (int) checklistDone,
                (int) checklistTotal);
    }
}
