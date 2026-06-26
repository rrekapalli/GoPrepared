package com.goprepared.api.service;

import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import com.goprepared.api.ai.workflows.ChecklistGenerationWorkflow;
import com.goprepared.api.ai.workflows.JourneyClassificationWorkflow;
import com.goprepared.api.domain.ChecklistItemEntity;
import com.goprepared.api.domain.Journey;
import com.goprepared.api.domain.User;
import com.goprepared.api.repository.ChecklistItemRepository;
import com.goprepared.api.repository.JourneyRepository;
import com.goprepared.api.web.dto.ApiDtos.AddChecklistItemRequest;
import com.goprepared.api.web.dto.ApiDtos.ChecklistItemResponse;
import com.goprepared.api.web.dto.ApiDtos.ChecklistResponse;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ChecklistService {

    private final ChecklistItemRepository checklistItemRepository;
    private final JourneyRepository journeyRepository;
    private final JourneyClassificationWorkflow classificationWorkflow;
    private final ChecklistGenerationWorkflow checklistGenerationWorkflow;

    @Transactional
    public ChecklistResponse getOrGenerateChecklist(User user, Long journeyId) {
        Journey journey = getOwnedJourney(user, journeyId);
        List<ChecklistItemEntity> items = checklistItemRepository.findByJourneyOrderByDisplayOrderAsc(journey);
        if (items.isEmpty()) {
            JourneyClassification classification = classificationWorkflow.classify(journey.getOriginalQuery());
            checklistGenerationWorkflow.generate(classification).forEach(ci -> checklistItemRepository.save(
                    ChecklistItemEntity.builder()
                            .journey(journey)
                            .title(ci.title())
                            .description(ci.description())
                            .category(ci.category())
                            .displayOrder(ci.displayOrder())
                            .completed(false)
                            .build()));
            items = checklistItemRepository.findByJourneyOrderByDisplayOrderAsc(journey);
        }
        return toResponse(journey, items);
    }

    @Transactional
    public ChecklistItemResponse completeItem(User user, Long itemId, boolean completed) {
        ChecklistItemEntity item = checklistItemRepository
                .findById(itemId)
                .orElseThrow(() -> new EntityNotFoundException("Checklist item not found"));
        if (!item.getJourney().getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Checklist item not found");
        }
        item.setCompleted(completed);
        checklistItemRepository.save(item);
        updateJourneyProgress(item.getJourney());
        return toItemResponse(item);
    }

    @Transactional
    public ChecklistItemResponse addUserItem(User user, Long journeyId, AddChecklistItemRequest request) {
        Journey journey = getOwnedJourney(user, journeyId);
        List<ChecklistItemEntity> existing = checklistItemRepository.findByJourneyOrderByDisplayOrderAsc(journey);
        int nextOrder = existing.stream().mapToInt(ChecklistItemEntity::getDisplayOrder).max().orElse(-1) + 1;
        String category = request.category() != null && !request.category().isBlank()
                ? request.category().trim()
                : "My items";
        ChecklistItemEntity item = ChecklistItemEntity.builder()
                .journey(journey)
                .title(request.title().trim())
                .description(request.description() != null ? request.description().trim() : "")
                .category(category)
                .displayOrder(nextOrder)
                .completed(false)
                .userAdded(true)
                .build();
        checklistItemRepository.save(item);
        return toItemResponse(item);
    }

    @Transactional
    public void deleteUserItem(User user, Long itemId) {
        ChecklistItemEntity item = checklistItemRepository
                .findById(itemId)
                .orElseThrow(() -> new EntityNotFoundException("Checklist item not found"));
        if (!item.getJourney().getUser().getId().equals(user.getId()) || !item.isUserAdded()) {
            throw new EntityNotFoundException("Checklist item not found");
        }
        Journey journey = item.getJourney();
        checklistItemRepository.delete(item);
        updateJourneyProgress(journey);
    }

    @Transactional
    public ChecklistItemResponse toggleComplete(User user, Long itemId) {
        ChecklistItemEntity item = checklistItemRepository
                .findById(itemId)
                .orElseThrow(() -> new EntityNotFoundException("Checklist item not found"));
        if (!item.getJourney().getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Checklist item not found");
        }
        item.setCompleted(!item.isCompleted());
        checklistItemRepository.save(item);
        updateJourneyProgress(item.getJourney());
        return toItemResponse(item);
    }

    private void updateJourneyProgress(Journey journey) {
        long total = checklistItemRepository.countByJourney(journey);
        if (total == 0) return;
        long done = checklistItemRepository.countByJourneyAndCompletedTrue(journey);
        int cardProgress = journey.getProgressPercent();
        int checklistProgress = (int) (done * 100 / total);
        journey.setProgressPercent((cardProgress + checklistProgress) / 2);
        journeyRepository.save(journey);
    }

    private ChecklistResponse toResponse(Journey journey, List<ChecklistItemEntity> items) {
        long done = items.stream().filter(ChecklistItemEntity::isCompleted).count();
        int percent = items.isEmpty() ? 0 : (int) (done * 100 / items.size());
        return new ChecklistResponse(
                journey.getId(),
                journey.getTitle() + " Essentials",
                percent,
                items.stream().map(this::toItemResponse).toList());
    }

    private ChecklistItemResponse toItemResponse(ChecklistItemEntity item) {
        return new ChecklistItemResponse(
                item.getId(),
                item.getTitle(),
                item.getDescription(),
                item.getCategory(),
                item.getDisplayOrder(),
                item.isCompleted(),
                item.isUserAdded());
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
}
