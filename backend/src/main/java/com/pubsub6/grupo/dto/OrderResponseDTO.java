package com.pubsub6.grupo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record OrderResponseDTO(
        String uuid,
        @JsonProperty("created_at") LocalDateTime createdAt,
        String channel,
        String status,
        CustomerDTO customer,
        SellerDTO seller,
        List<OrderItemResponseDTO> items,
        ShipmentDTO shipment,
        PaymentDTO payment,
        OrderMetadataDTO metadata,
        @JsonProperty("indexed_at") LocalDateTime indexedAt,
        BigDecimal total
) {}
