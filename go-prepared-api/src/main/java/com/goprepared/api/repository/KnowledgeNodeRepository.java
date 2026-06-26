package com.goprepared.api.repository;

import com.goprepared.api.domain.KnowledgeNodeEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface KnowledgeNodeRepository extends JpaRepository<KnowledgeNodeEntity, Long> {
    List<KnowledgeNodeEntity> findByNodeType(String nodeType);

    Optional<KnowledgeNodeEntity> findByNodeTypeAndNameIgnoreCase(String nodeType, String name);

    Optional<KnowledgeNodeEntity> findByNameIgnoreCase(String name);
}
