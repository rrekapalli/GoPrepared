package com.goprepared.api.domain;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.*;

@Entity
@Table(name = "journeys")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Journey {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String title;

    @Column(name = "original_query", nullable = false)
    private String originalQuery;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "journey_type_id")
    private JourneyType journeyType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "journey_subtype_id")
    private JourneySubtype journeySubtype;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "activity_id")
    private Activity activity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "location_id")
    private Location location;

    private String status;

    @Column(name = "progress_percent")
    private int progressPercent;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
        if (status == null) status = "DRAFT";
    }
}
