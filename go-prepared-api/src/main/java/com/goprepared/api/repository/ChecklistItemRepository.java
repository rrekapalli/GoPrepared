package com.goprepared.api.repository;

import com.goprepared.api.domain.ChecklistItemEntity;
import com.goprepared.api.domain.Journey;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChecklistItemRepository extends JpaRepository<ChecklistItemEntity, Long> {
    List<ChecklistItemEntity> findByJourneyOrderByDisplayOrderAsc(Journey journey);

    long countByJourney(Journey journey);

    long countByJourneyAndCompletedTrue(Journey journey);
}
