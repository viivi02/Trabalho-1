package com.pubsub6.grupo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDateTime;
import java.util.List;

public record OrderDTO(
        String uuid,
        @JsonProperty("created_at")
        LocalDateTime createdAt,
        String channel,
        String status,
        CustomerDTO customer,
        SellerDTO seller,
        List<OrderItemDTO> items,
        ShipmentDTO shipment,
        PaymentDTO payment,
        OrderMetadataDTO metadata
) {}
