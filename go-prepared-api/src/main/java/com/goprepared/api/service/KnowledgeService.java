package com.goprepared.api.service;

import com.goprepared.api.domain.KnowledgeEdgeEntity;
import com.goprepared.api.repository.ContentTemplateRepository;
import com.goprepared.api.repository.KnowledgeEdgeRepository;
import com.goprepared.api.repository.KnowledgeNodeRepository;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeCategoryResponse;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeEdgeResponse;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeNodeResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class KnowledgeService {

    private final KnowledgeNodeRepository knowledgeNodeRepository;
    private final KnowledgeEdgeRepository knowledgeEdgeRepository;
    private final ContentTemplateRepository contentTemplateRepository;

    @Transactional(readOnly = true)
    public List<KnowledgeCategoryResponse> categories() {
        long travel = contentTemplateRepository.findByTypeAndLocation("Travel", "").size();
        return List.of(
                new KnowledgeCategoryResponse("Travel", "airplane", Math.max(128, (int) travel * 40)),
                new KnowledgeCategoryResponse("Sports", "soccer", 64),
                new KnowledgeCategoryResponse("Education", "graduation", 96),
                new KnowledgeCategoryResponse("Career", "briefcase", 42),
                new KnowledgeCategoryResponse("Finance", "bank", 38),
                new KnowledgeCategoryResponse("Health", "heart", 55));
    }

    @Transactional(readOnly = true)
    public List<KnowledgeNodeResponse> nodes() {
        return knowledgeNodeRepository.findAll().stream()
                .map(n -> new KnowledgeNodeResponse(n.getNodeType(), n.getName(), n.getDescription()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<KnowledgeEdgeResponse> relationships() {
        return knowledgeEdgeRepository.findAllWithNodes().stream()
                .map(this::toEdgeResponse)
                .toList();
    }

    private KnowledgeEdgeResponse toEdgeResponse(KnowledgeEdgeEntity edge) {
        return new KnowledgeEdgeResponse(
                edge.getSourceNode().getName(),
                edge.getTargetNode().getName(),
                edge.getRelationshipType());
    }
}
