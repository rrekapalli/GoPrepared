package com.goprepared.api.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "community_insight_votes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommunityInsightVoteEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "insight_id", nullable = false)
    private CommunityInsightEntity insight;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private boolean helpful;
}
