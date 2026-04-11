package com.pubsub6.grupo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record PaymentDTO(
        String method, String status,
        @JsonProperty("transaction_id") String transactionId
) {}
