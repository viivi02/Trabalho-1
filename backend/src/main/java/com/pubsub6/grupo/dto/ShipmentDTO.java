package com.pubsub6.grupo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record ShipmentDTO(
        String carrier, String service, String status,
        @JsonProperty("tracking_code") String trackingCode
) {}