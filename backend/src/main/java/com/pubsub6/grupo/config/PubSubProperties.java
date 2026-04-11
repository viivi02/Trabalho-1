package com.pubsub6.grupo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.pubsub")
public record PubSubProperties(
        String projectId,
        String subscriptionId,
        String credentialsPath
) {}
