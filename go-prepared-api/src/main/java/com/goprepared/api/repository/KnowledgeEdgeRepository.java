package com.goprepared.api.repository;

import com.goprepared.api.domain.KnowledgeEdgeEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface KnowledgeEdgeRepository extends JpaRepository<KnowledgeEdgeEntity, Long> {

    @Query("""
        SELECT e FROM KnowledgeEdgeEntity e
        JOIN FETCH e.sourceNode
        JOIN FETCH e.targetNode
        """)
    List<KnowledgeEdgeEntity> findAllWithNodes();

    boolean existsBySourceNodeIdAndTargetNodeIdAndRelationshipType(
            Long sourceNodeId, Long targetNodeId, String relationshipType);
}
