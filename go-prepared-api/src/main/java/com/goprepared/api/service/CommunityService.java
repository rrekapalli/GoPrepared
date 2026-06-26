package com.goprepared.api.service;

import com.goprepared.api.domain.CommunityInsightEntity;
import com.goprepared.api.domain.CommunityInsightVoteEntity;
import com.goprepared.api.domain.Journey;
import com.goprepared.api.domain.User;
import com.goprepared.api.repository.CommunityInsightRepository;
import com.goprepared.api.repository.CommunityInsightVoteRepository;
import com.goprepared.api.repository.JourneyRepository;
import com.goprepared.api.web.dto.ApiDtos.CommunityInsightResponse;
import com.goprepared.api.web.dto.ApiDtos.ContributeInsightRequest;
import com.goprepared.api.web.dto.ApiDtos.VoteInsightRequest;
import com.goprepared.api.web.dto.ApiDtos.VoteInsightResponse;
import jakarta.persistence.EntityNotFoundException;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CommunityService {

    private final CommunityInsightRepository communityInsightRepository;
    private final CommunityInsightVoteRepository communityInsightVoteRepository;
    private final JourneyRepository journeyRepository;

    @Transactional(readOnly = true)
    public List<CommunityInsightResponse> listInsights() {
        return communityInsightRepository.findByStatusOrderByVotesDesc("ACTIVE").stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public CommunityInsightResponse contribute(User user, ContributeInsightRequest request) {
        Journey journey = null;
        if (request.journeyId() != null) {
            journey = journeyRepository
                    .findById(request.journeyId())
                    .filter(j -> j.getUser().getId().equals(user.getId()))
                    .orElse(null);
        }
        CommunityInsightEntity entity = CommunityInsightEntity.builder()
                .user(user)
                .journey(journey)
                .insightType(request.insightType().toUpperCase())
                .title(request.title())
                .content(request.content())
                .journeyContext(request.journeyContext())
                .severity(request.severity())
                .votes(0)
                .status("ACTIVE")
                .createdAt(Instant.now())
                .build();
        return toResponse(communityInsightRepository.save(entity));
    }

    @Transactional
    public VoteInsightResponse vote(User user, VoteInsightRequest request) {
        CommunityInsightEntity insight = communityInsightRepository
                .findById(request.insightId())
                .orElseThrow(() -> new EntityNotFoundException("Insight not found"));

        var existing = communityInsightVoteRepository.findByInsightAndUser(insight, user);
        if (existing.isPresent()) {
            CommunityInsightVoteEntity vote = existing.get();
            if (vote.isHelpful() != request.helpful()) {
                if (request.helpful()) {
                    insight.setVotes(insight.getVotes() + 2);
                } else {
                    insight.setVotes(Math.max(0, insight.getVotes() - 2));
                }
                vote.setHelpful(request.helpful());
                communityInsightVoteRepository.save(vote);
            }
        } else {
            communityInsightVoteRepository.save(CommunityInsightVoteEntity.builder()
                    .insight(insight)
                    .user(user)
                    .helpful(request.helpful())
                    .build());
            if (request.helpful()) {
                insight.setVotes(insight.getVotes() + 1);
            } else {
                insight.setVotes(Math.max(0, insight.getVotes() - 1));
            }
        }
        communityInsightRepository.save(insight);
        return new VoteInsightResponse(insight.getId(), insight.getVotes(), request.helpful());
    }

    private CommunityInsightResponse toResponse(CommunityInsightEntity e) {
        return new CommunityInsightResponse(
                e.getId(),
                e.getInsightType(),
                e.getTitle(),
                e.getContent(),
                e.getJourneyContext(),
                e.getSeverity(),
                e.getVotes());
    }
}
