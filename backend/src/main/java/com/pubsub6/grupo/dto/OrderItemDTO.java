package com.pubsub6.grupo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;

public record OrderItemDTO(
        Long id,
        @JsonProperty("product_id") Long productId,
        @JsonProperty("product_name") String productName,
        @JsonProperty("unit_price") BigDecimal unitPrice,
        Integer quantity,
        CategoryDTO category
) {}
