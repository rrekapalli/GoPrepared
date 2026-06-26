package com.goprepared.api.repository;

import com.goprepared.api.domain.Activity;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ActivityRepository extends JpaRepository<Activity, Long> {
    Optional<Activity> findByNameIgnoreCase(String name);
}
