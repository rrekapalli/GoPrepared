package com.goprepared.api.repository;

import com.goprepared.api.domain.JourneySubtype;
import com.goprepared.api.domain.JourneyType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JourneySubtypeRepository extends JpaRepository<JourneySubtype, Long> {
    Optional<JourneySubtype> findByJourneyTypeAndNameIgnoreCase(JourneyType journeyType, String name);
}
