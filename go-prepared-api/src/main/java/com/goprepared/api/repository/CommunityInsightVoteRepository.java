package com.goprepared.api.repository;

import com.goprepared.api.domain.CommunityInsightEntity;
import com.goprepared.api.domain.CommunityInsightVoteEntity;
import com.goprepared.api.domain.User;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommunityInsightVoteRepository extends JpaRepository<CommunityInsightVoteEntity, Long> {
    Optional<CommunityInsightVoteEntity> findByInsightAndUser(CommunityInsightEntity insight, User user);
}
