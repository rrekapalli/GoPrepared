package com.goprepared.api.ai.workflows;

import com.goprepared.api.ai.dto.AiContracts.KnowledgeEdge;
import com.goprepared.api.ai.dto.AiContracts.KnowledgeNode;
import java.util.Collections;
import java.util.List;
import org.springframework.stereotype.Service;

/** @Mvp3Stub */
@Service
public class KnowledgeExtractionWorkflow {
    public record ExtractResult(List<KnowledgeNode> nodes, List<KnowledgeEdge> edges) {}

    public ExtractResult extract() {
        return new ExtractResult(Collections.emptyList(), Collections.emptyList());
    }
}
