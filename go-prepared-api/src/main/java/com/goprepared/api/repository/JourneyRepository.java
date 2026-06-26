package com.goprepared.api.repository;

import com.goprepared.api.domain.Journey;
import com.goprepared.api.domain.User;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JourneyRepository extends JpaRepository<Journey, Long> {
    List<Journey> findByUserOrderByCreatedAtDesc(User user);
}
