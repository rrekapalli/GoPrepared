package com.goprepared.api.service;

import com.goprepared.api.repository.ContentTemplateRepository;
import com.goprepared.api.repository.KnowledgeEdgeRepository;
import com.goprepared.api.repository.KnowledgeNodeRepository;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeCategoryResponse;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeEdgeResponse;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeNodeResponse;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeTemplateResponse;
import com.goprepared.api.domain.ContentTemplate;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class KnowledgeService {

    private static final Map<String, String> CATEGORY_ICONS = Map.of(
            "Travel", "airplane",
            "Sports", "soccer",
            "Education", "graduation",
            "Career", "briefcase",
            "Finance", "bank",
            "Health", "heart");

    private final KnowledgeNodeRepository knowledgeNodeRepository;
    private final KnowledgeEdgeRepository knowledgeEdgeRepository;
    private final ContentTemplateRepository contentTemplateRepository;

    @Transactional(readOnly = true)
    public List<KnowledgeCategoryResponse> categories() {
        return List.of(
                category("Travel"),
                category("Sports"),
                category("Education"),
                category("Health"),
                category("Career"),
                category("Finance"));
    }

    private KnowledgeCategoryResponse category(String name) {
        long nodeCount = knowledgeNodeRepository.countByMetadataCategory(name);
        long templateCount = contentTemplateRepository.findAll().stream()
                .filter(t -> name.equalsIgnoreCase(t.getJourneyType()))
                .count();
        int journeys = (int) Math.max(nodeCount * 12, templateCount * 8);
        return new KnowledgeCategoryResponse(
                name, CATEGORY_ICONS.getOrDefault(name, "book"), Math.max(journeys, 10));
    }

    @Transactional(readOnly = true)
    public List<KnowledgeNodeResponse> nodes(String category) {
        return knowledgeNodeRepository.findAll().stream()
                .filter(n -> category == null
                        || category.isBlank()
                        || category.equalsIgnoreCase(n.getNodeType())
                        || (n.getMetadata() != null
                                && category.equalsIgnoreCase(String.valueOf(n.getMetadata().get("category")))))
                .map(n -> new KnowledgeNodeResponse(n.getNodeType(), n.getName(), n.getDescription()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<KnowledgeTemplateResponse> templates(String journeyType) {
        return contentTemplateRepository.findAll().stream()
                .filter(t -> journeyType == null
                        || journeyType.isBlank()
                        || journeyType.equalsIgnoreCase(t.getJourneyType()))
                .map(this::toTemplateResponse)
                .toList();
    }

    private KnowledgeTemplateResponse toTemplateResponse(ContentTemplate template) {
        String title = templateTitle(template);
        String suggested = title.isBlank() ? template.getLocation() : title;
        if (suggested != null && !suggested.isBlank() && template.getLocation() != null) {
            suggested = title + " — " + template.getLocation();
        }
        return new KnowledgeTemplateResponse(
                template.getTemplateKey(),
                title.isBlank() ? template.getTemplateKey() : title,
                template.getJourneyType(),
                template.getJourneySubtype(),
                template.getActivity(),
                template.getLocation(),
                suggested);
    }

    @SuppressWarnings("unchecked")
    private String templateTitle(ContentTemplate template) {
        Map<String, Object> payload = template.getPayload();
        if (payload == null) {
            return "";
        }
        Object classification = payload.get("classification");
        if (!(classification instanceof Map<?, ?> map)) {
            return "";
        }
        Object title = map.get("title");
        return title != null ? title.toString() : "";
    }

    @Transactional(readOnly = true)
    public List<KnowledgeEdgeResponse> relationships() {
        return knowledgeEdgeRepository.findAllWithNodes().stream()
                .map(this::toEdgeResponse)
                .toList();
    }

    private KnowledgeEdgeResponse toEdgeResponse(com.goprepared.api.domain.KnowledgeEdgeEntity edge) {
        return new KnowledgeEdgeResponse(
                edge.getSourceNode().getName(),
                edge.getTargetNode().getName(),
                edge.getRelationshipType());
    }
}
