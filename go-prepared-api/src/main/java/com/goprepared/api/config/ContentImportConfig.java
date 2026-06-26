package com.goprepared.api.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.goprepared.api.domain.CommunityInsightEntity;
import com.goprepared.api.domain.ContentTemplate;
import com.goprepared.api.domain.KnowledgeEdgeEntity;
import com.goprepared.api.domain.KnowledgeNodeEntity;
import com.goprepared.api.repository.CommunityInsightRepository;
import com.goprepared.api.repository.ContentTemplateRepository;
import com.goprepared.api.repository.KnowledgeEdgeRepository;
import com.goprepared.api.repository.KnowledgeNodeRepository;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class ContentImportConfig {

    private final ContentTemplateRepository contentTemplateRepository;
    private final KnowledgeNodeRepository knowledgeNodeRepository;
    private final KnowledgeEdgeRepository knowledgeEdgeRepository;
    private final CommunityInsightRepository communityInsightRepository;
    private final ObjectMapper objectMapper;
    private final GoPreparedContentProperties contentProperties;

    @Bean
    CommandLineRunner importStaticContent() {
        return args -> {
            if (!contentProperties.isSyncOnStartup()) {
                log.info("Content sync disabled (goprepared.content.sync-on-startup=false)");
                return;
            }
            Path output = Paths.get(contentProperties.getContentPath());
            if (!Files.isDirectory(output)) {
                log.warn("Static content output not found at {}", output.toAbsolutePath());
                return;
            }
            int templates = importJourneyTemplates(output.resolve("journey-templates"));
            int nodes = importKnowledge(output.resolve("knowledge/graph.json"));
            int community = importCommunityIfEmpty(output.resolve("community/featured.json"));
            log.info(
                    "Content sync complete: {} templates upserted, {} knowledge nodes upserted, {} community insights",
                    templates,
                    nodes,
                    community);
        };
    }

    private int importJourneyTemplates(Path dir) {
        if (!Files.isDirectory(dir)) {
            return 0;
        }
        int count = 0;
        try (var stream = Files.list(dir)) {
            for (Path p : stream.filter(path -> path.toString().endsWith(".json")).toList()) {
                try {
                    Map<String, Object> payload = objectMapper.readValue(p.toFile(), new TypeReference<>() {});
                    String templateKey = (String) payload.get("templateKey");
                    if (templateKey == null) {
                        continue;
                    }
                    @SuppressWarnings("unchecked")
                    Map<String, Object> classification = (Map<String, Object>) payload.get("classification");
                    ContentTemplate template = contentTemplateRepository
                            .findByTemplateKey(templateKey)
                            .map(existing -> {
                                existing.setJourneyType((String) classification.get("journeyType"));
                                existing.setJourneySubtype((String) classification.get("journeySubtype"));
                                existing.setActivity((String) classification.get("activity"));
                                existing.setLocation((String) classification.get("location"));
                                existing.setPayload(payload);
                                return existing;
                            })
                            .orElseGet(() -> ContentTemplate.builder()
                                    .templateKey(templateKey)
                                    .journeyType((String) classification.get("journeyType"))
                                    .journeySubtype((String) classification.get("journeySubtype"))
                                    .activity((String) classification.get("activity"))
                                    .location((String) classification.get("location"))
                                    .payload(payload)
                                    .createdAt(Instant.now())
                                    .build());
                    contentTemplateRepository.save(template);
                    count++;
                } catch (Exception e) {
                    log.error("Failed to import {}", p, e);
                }
            }
        } catch (Exception e) {
            log.error("Failed to list journey templates in {}", dir, e);
        }
        return count;
    }

    private int importKnowledge(Path file) {
        if (!Files.exists(file)) {
            return 0;
        }
        try {
            Map<String, Object> graph = objectMapper.readValue(file.toFile(), new TypeReference<>() {});
            int nodes = upsertKnowledgeNodes(graph);
            upsertKnowledgeEdges(graph);
            return nodes;
        } catch (Exception e) {
            log.error("Failed to import knowledge from {}", file, e);
            return 0;
        }
    }

    @SuppressWarnings("unchecked")
    private int upsertKnowledgeNodes(Map<String, Object> graph) {
        List<Map<String, Object>> nodes = (List<Map<String, Object>>) graph.get("nodes");
        if (nodes == null) {
            return 0;
        }
        int count = 0;
        for (Map<String, Object> n : nodes) {
            String nodeType = (String) n.get("nodeType");
            String name = (String) n.get("name");
            if (nodeType == null || name == null) {
                continue;
            }
            Map<String, Object> metadata = null;
            Object rawMetadata = n.get("metadata");
            if (rawMetadata instanceof Map<?, ?> metaMap) {
                metadata = objectMapper.convertValue(metaMap, new TypeReference<>() {});
            }
            KnowledgeNodeEntity entity = knowledgeNodeRepository
                    .findByNodeTypeAndNameIgnoreCase(nodeType, name)
                    .orElseGet(() -> KnowledgeNodeEntity.builder()
                            .nodeType(nodeType)
                            .name(name)
                            .build());
            entity.setDescription((String) n.get("description"));
            entity.setMetadata(metadata);
            knowledgeNodeRepository.save(entity);
            count++;
        }
        return count;
    }

    @SuppressWarnings("unchecked")
    private void upsertKnowledgeEdges(Map<String, Object> graph) {
        List<Map<String, Object>> edges = (List<Map<String, Object>>) graph.get("edges");
        if (edges == null) {
            return;
        }
        for (Map<String, Object> edge : edges) {
            try {
                String sourceName = (String) edge.get("sourceName");
                String targetName = (String) edge.get("targetName");
                String relationshipType = (String) edge.get("relationshipType");
                if (sourceName == null || targetName == null || relationshipType == null) {
                    continue;
                }
                var source = resolveNode(sourceName, (String) edge.get("sourceType"));
                var target = resolveNode(targetName, (String) edge.get("targetType"));
                if (source.isEmpty() || target.isEmpty()) {
                    log.warn("Could not resolve edge {} -> {}", sourceName, targetName);
                    continue;
                }
                if (knowledgeEdgeRepository.existsBySourceNodeIdAndTargetNodeIdAndRelationshipType(
                        source.get().getId(), target.get().getId(), relationshipType)) {
                    continue;
                }
                knowledgeEdgeRepository.save(KnowledgeEdgeEntity.builder()
                        .sourceNode(source.get())
                        .targetNode(target.get())
                        .relationshipType(relationshipType)
                        .build());
            } catch (Exception e) {
                log.warn("Skipping edge {}: {}", edge, e.getMessage());
            }
        }
    }

    private Optional<KnowledgeNodeEntity> resolveNode(String name, String nodeType) {
        if (nodeType != null && !nodeType.isBlank()) {
            return knowledgeNodeRepository.findByNodeTypeAndNameIgnoreCase(nodeType, name);
        }
        var matches = knowledgeNodeRepository.findAllByNameIgnoreCase(name);
        if (matches.isEmpty()) {
            return Optional.empty();
        }
        if (matches.size() > 1) {
            log.warn(
                    "Ambiguous knowledge node name '{}' ({} matches) — using {}",
                    name,
                    matches.size(),
                    matches.get(0).getNodeType());
        }
        return Optional.of(matches.get(0));
    }

    private int importCommunityIfEmpty(Path file) {
        if (!Files.exists(file) || communityInsightRepository.count() > 0) {
            return 0;
        }
        try {
            List<Map<String, Object>> items = objectMapper.readValue(file.toFile(), new TypeReference<>() {});
            for (Map<String, Object> item : items) {
                communityInsightRepository.save(CommunityInsightEntity.builder()
                        .insightType((String) item.get("insightType"))
                        .title((String) item.get("title"))
                        .content((String) item.get("content"))
                        .journeyContext((String) item.get("journeyContext"))
                        .severity(item.get("severity") != null ? item.get("severity").toString() : null)
                        .votes(126)
                        .status("ACTIVE")
                        .createdAt(Instant.now())
                        .build());
            }
            return items.size();
        } catch (Exception e) {
            log.error("Failed to import community insights from {}", file, e);
            return 0;
        }
    }
}
