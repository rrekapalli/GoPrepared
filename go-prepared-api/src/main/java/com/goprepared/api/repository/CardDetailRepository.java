package com.goprepared.api.repository;

import com.goprepared.api.domain.Card;
import com.goprepared.api.domain.CardDetailEntity;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CardDetailRepository extends JpaRepository<CardDetailEntity, Long> {
    Optional<CardDetailEntity> findByCard(Card card);
}
