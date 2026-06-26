package com.goprepared.api.ai.workflows;

import com.goprepared.api.ai.dto.AiContracts.UserQueryResponse;
import com.goprepared.api.ai.rag.StaticContentRetrievalService;
import com.goprepared.api.domain.ContentTemplate;
import com.goprepared.api.domain.Journey;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserQueryWorkflow {

    private final Optional<ChatClient.Builder> chatClientBuilder;
    private final StaticContentRetrievalService staticContent;

    public UserQueryResponse answer(Journey journey, String question) {
        Optional<ContentTemplate> template = staticContent.findBestTemplate(journey.getOriginalQuery());
        String context = template.map(staticContent::buildContextSnippet).orElse(journey.getTitle());

        if (chatClientBuilder.isEmpty()) {
            return new UserQueryResponse(
                    "Based on your %s preparation: %s".formatted(journey.getTitle(), question));
        }
        try {
            String prompt = """
                You are GoPrepared assistant. Answer briefly using this context.
                Journey: %s
                Original query: %s
                Context: %s
                Question: %s
                """
                    .formatted(
                            journey.getTitle(),
                            journey.getOriginalQuery(),
                            context,
                            question);

            String answer = chatClientBuilder.get().build().prompt(prompt).call().content();
            return new UserQueryResponse(answer);
        } catch (Exception ex) {
            log.warn("User query AI failed: {}", ex.getMessage());
            return new UserQueryResponse(
                    "I found context for %s. Regarding \"%s\": check your preparation cards for details."
                            .formatted(journey.getTitle(), question));
        }
    }
}
