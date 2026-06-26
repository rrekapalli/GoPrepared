package com.goprepared.api.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "journey_subtypes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class JourneySubtype {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "journey_type_id")
    private JourneyType journeyType;

    private String name;
}
