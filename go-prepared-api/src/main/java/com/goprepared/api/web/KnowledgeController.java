package com.goprepared.api.web;

import com.goprepared.api.service.KnowledgeService;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeCategoryResponse;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeEdgeResponse;
import com.goprepared.api.web.dto.ApiDtos.KnowledgeNodeResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/knowledge")
@RequiredArgsConstructor
@Tag(name = "Knowledge")
public class KnowledgeController {

    private final KnowledgeService knowledgeService;

    @GetMapping("/categories")
    public List<KnowledgeCategoryResponse> categories() {
        return knowledgeService.categories();
    }

    @GetMapping("/nodes")
    public List<KnowledgeNodeResponse> nodes() {
        return knowledgeService.nodes();
    }

    @GetMapping("/relationships")
    public List<KnowledgeEdgeResponse> relationships() {
        return knowledgeService.relationships();
    }
}
