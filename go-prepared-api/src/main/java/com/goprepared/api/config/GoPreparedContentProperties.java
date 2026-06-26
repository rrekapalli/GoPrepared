package com.goprepared.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "goprepared.content")
@Getter
@Setter
public class GoPreparedContentProperties {
    /** When true, merge journey templates and knowledge graph from go-prepared-content/output on startup. */
    private boolean syncOnStartup = true;
    private String contentPath = "../go-prepared-content/output";
}
