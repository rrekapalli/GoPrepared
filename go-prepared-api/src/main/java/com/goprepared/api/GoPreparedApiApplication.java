package com.goprepared.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import com.goprepared.api.config.GoPreparedContentProperties;

@SpringBootApplication
@EnableConfigurationProperties(GoPreparedContentProperties.class)
public class GoPreparedApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(GoPreparedApiApplication.class, args);
    }
}
