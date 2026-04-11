package com.pubsub6.grupo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record OrderMetadataDTO(
        String source,
        @JsonProperty("user_agent") String userAgent,
        @JsonProperty("ip_address") String ipAddress
) {}
