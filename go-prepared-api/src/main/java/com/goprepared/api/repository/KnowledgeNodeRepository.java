package com.goprepared.api.repository;

import com.goprepared.api.domain.KnowledgeNodeEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface KnowledgeNodeRepository extends JpaRepository<KnowledgeNodeEntity, Long> {
    List<KnowledgeNodeEntity> findByNodeType(String nodeType);

    Optional<KnowledgeNodeEntity> findByNodeTypeAndNameIgnoreCase(String nodeType, String name);

    Optional<KnowledgeNodeEntity> findByNameIgnoreCase(String name);

    List<KnowledgeNodeEntity> findAllByNameIgnoreCase(String name);

    long countByNodeType(String nodeType);

    @Query(value = "SELECT COUNT(*) FROM knowledge_nodes WHERE metadata->>'category' = :category", nativeQuery = true)
    long countByMetadataCategory(@Param("category") String category);
}
