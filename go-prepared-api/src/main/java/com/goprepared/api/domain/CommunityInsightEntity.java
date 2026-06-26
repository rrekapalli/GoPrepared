package com.goprepared.api.domain;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.*;

@Entity
@Table(name = "community_insights")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommunityInsightEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "journey_id")
    private Journey journey;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "insight_type", nullable = false)
    private String insightType;

    private String title;

    @Column(nullable = false)
    private String content;

    private int votes;
    private String status;
    private String severity;

    @Column(name = "journey_context")
    private String journeyContext;

    @Column(name = "created_at")
    private Instant createdAt;
}
