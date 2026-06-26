package com.goprepared.api.ai.workflows;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import com.goprepared.api.ai.rag.StaticContentRetrievalService;
import com.goprepared.api.domain.ContentTemplate;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class JourneyClassificationWorkflow {

    private final Optional<ChatClient.Builder> chatClientBuilder;
    private final StaticContentRetrievalService staticContent;
    private final ObjectMapper objectMapper;

    @Value("${goprepared.ai.fallback-to-static:true}")
    private boolean fallbackToStatic;

    public JourneyClassification classify(String query) {
        Optional<ContentTemplate> template = staticContent.findBestTemplate(query);
        if (fallbackToStatic && template.isPresent()) {
            return staticContent.classificationFromTemplate(template.get());
        }
        return classifyWithAi(query, template.orElse(null));
    }

    private JourneyClassification classifyWithAi(String query, ContentTemplate template) {
        if (chatClientBuilder.isEmpty()) {
            return heuristicClassification(query);
        }
        try {
            String context = template != null ? staticContent.buildContextSnippet(template) : "";
            String prompt = """
                Classify this preparation query into structured JSON with fields:
                journeyType, journeySubtype, activity, location, title, confidence.
                Query: %s
                Context: %s
                Respond with JSON only.
                """.formatted(query, context);

            String response = chatClientBuilder.get().build().prompt(prompt).call().content();
            return objectMapper.readValue(response, JourneyClassification.class);
        } catch (Exception ex) {
            log.warn("AI classification failed, using heuristic: {}", ex.getMessage());
            return heuristicClassification(query);
        }
    }

    private JourneyClassification heuristicClassification(String query) {
        String q = query.toLowerCase(Locale.ROOT);
        if (q.contains("bali") || q.contains("vacation")) {
            return new JourneyClassification("Travel", "Vacation", "Vacation", "Bali", "Vacation to Bali", 0.8);
        }
        if (q.contains("10k") || q.contains("vizag")) {
            return new JourneyClassification("Sports", "10K Run", "Running", "Vizag", "Vizag 10K Run", 0.8);
        }
        if (q.contains("angiogram")) {
            return new JourneyClassification(
                    "Health", "Medical Procedure", "Angiogram", "", "Going for an Angiogram", 0.8);
        }
        return new JourneyClassification("Personal", "General", "Preparation", "", query, 0.5);
    }
}
