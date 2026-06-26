package com.goprepared.api.ai.config;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SpringAiConfig {

    @Bean
    @ConditionalOnBean(ChatClient.Builder.class)
    ChatClient chatClient(ChatClient.Builder builder) {
        return builder.build();
    }
}
