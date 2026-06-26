package com.goprepared.api.repository;

import com.goprepared.api.domain.CommunityInsightEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommunityInsightRepository extends JpaRepository<CommunityInsightEntity, Long> {
    List<CommunityInsightEntity> findByStatusOrderByVotesDesc(String status);
}
