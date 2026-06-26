package com.goprepared.api.repository;

import com.goprepared.api.domain.JourneyType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JourneyTypeRepository extends JpaRepository<JourneyType, Long> {
    Optional<JourneyType> findByNameIgnoreCase(String name);
}
