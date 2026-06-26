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

    @Bean
    CommandLineRunner importStaticContent() {
        return args -> {
            if (contentTemplateRepository.count() > 0) {
                importKnowledgeEdgesIfMissing();
                return;
            }
            Path output = Paths.get("../go-prepared-content/output");
            if (!Files.isDirectory(output)) {
                log.warn("Static content output not found at {}", output.toAbsolutePath());
                return;
            }
            importJourneyTemplates(output.resolve("journey-templates"));
            importKnowledge(output.resolve("knowledge/graph.json"));
            importCommunity(output.resolve("community/featured.json"));
            log.info("Imported static content from {}", output.toAbsolutePath());
        };
    }

    private void importKnowledgeEdgesIfMissing() {
        if (knowledgeEdgeRepository.count() > 0) {
            return;
        }
        Path graphFile = Paths.get("../go-prepared-content/output/knowledge/graph.json");
        if (!Files.exists(graphFile)) {
            return;
        }
        try {
            importKnowledgeEdges(graphFile);
            log.info("Imported knowledge edges from {}", graphFile.toAbsolutePath());
        } catch (Exception e) {
            log.error("Failed to import knowledge edges", e);
        }
    }

    private void importJourneyTemplates(Path dir) throws Exception {
        if (!Files.isDirectory(dir)) return;
        try (var stream = Files.list(dir)) {
            stream.filter(p -> p.toString().endsWith(".json")).forEach(p -> {
                try {
                    Map<String, Object> payload = objectMapper.readValue(p.toFile(), new TypeReference<>() {});
                    @SuppressWarnings("unchecked")
                    Map<String, Object> classification = (Map<String, Object>) payload.get("classification");
                    ContentTemplate template = ContentTemplate.builder()
                            .templateKey((String) payload.get("templateKey"))
                            .journeyType((String) classification.get("journeyType"))
                            .journeySubtype((String) classification.get("journeySubtype"))
                            .activity((String) classification.get("activity"))
                            .location((String) classification.get("location"))
                            .payload(payload)
                            .build();
                    contentTemplateRepository.save(template);
                } catch (Exception e) {
                    log.error("Failed to import {}", p, e);
                }
            });
        }
    }

    private void importKnowledge(Path file) throws Exception {
        if (!Files.exists(file)) return;
        Map<String, Object> graph = objectMapper.readValue(file.toFile(), new TypeReference<>() {});
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> nodes = (List<Map<String, Object>>) graph.get("nodes");
        if (nodes != null) {
            for (Map<String, Object> n : nodes) {
                String nodeType = (String) n.get("nodeType");
                String name = (String) n.get("name");
                if (knowledgeNodeRepository.findByNodeTypeAndNameIgnoreCase(nodeType, name).isPresent()) {
                    continue;
                }
                knowledgeNodeRepository.save(KnowledgeNodeEntity.builder()
                        .nodeType(nodeType)
                        .name(name)
                        .description((String) n.get("description"))
                        .build());
            }
        }
        importKnowledgeEdges(file, graph);
    }

    private void importKnowledgeEdges(Path file) throws Exception {
        Map<String, Object> graph = objectMapper.readValue(file.toFile(), new TypeReference<>() {});
        importKnowledgeEdges(file, graph);
    }

    private void importKnowledgeEdges(Path file, Map<String, Object> graph) {
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> edges = (List<Map<String, Object>>) graph.get("edges");
        if (edges == null) return;
        for (Map<String, Object> edge : edges) {
            String sourceName = (String) edge.get("sourceName");
            String targetName = (String) edge.get("targetName");
            String relationshipType = (String) edge.get("relationshipType");
            if (sourceName == null || targetName == null || relationshipType == null) {
                log.warn("Skipping invalid edge in {}: {}", file, edge);
                continue;
            }
            var source = knowledgeNodeRepository.findByNameIgnoreCase(sourceName);
            var target = knowledgeNodeRepository.findByNameIgnoreCase(targetName);
            if (source.isEmpty() || target.isEmpty()) {
                log.warn("Could not resolve edge {} -> {} in {}", sourceName, targetName, file);
                continue;
            }
            knowledgeEdgeRepository.save(KnowledgeEdgeEntity.builder()
                    .sourceNode(source.get())
                    .targetNode(target.get())
                    .relationshipType(relationshipType)
                    .build());
        }
    }

    private void importCommunity(Path file) throws Exception {
        if (!Files.exists(file)) return;
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
    }
}
