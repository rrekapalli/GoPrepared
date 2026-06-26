package com.goprepared.api.repository;

import com.goprepared.api.domain.Card;
import com.goprepared.api.domain.Journey;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByJourneyOrderByDisplayOrderAsc(Journey journey);
}
