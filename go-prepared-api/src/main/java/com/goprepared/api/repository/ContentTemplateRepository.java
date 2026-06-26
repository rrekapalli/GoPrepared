package com.goprepared.api.repository;

import com.goprepared.api.domain.ContentTemplate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ContentTemplateRepository extends JpaRepository<ContentTemplate, Long> {
    Optional<ContentTemplate> findByTemplateKey(String templateKey);

    @Query("""
        SELECT t FROM ContentTemplate t
        WHERE lower(t.journeyType) = lower(:journeyType)
          AND (lower(t.location) = lower(:location) OR :location = '')
        """)
    List<ContentTemplate> findByTypeAndLocation(
            @Param("journeyType") String journeyType, @Param("location") String location);
}
