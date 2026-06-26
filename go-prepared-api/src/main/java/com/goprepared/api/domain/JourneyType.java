package com.goprepared.api.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "journey_types")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class JourneyType {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
}
