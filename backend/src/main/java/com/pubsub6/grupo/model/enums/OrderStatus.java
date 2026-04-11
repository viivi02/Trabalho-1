package com.pubsub6.grupo.model.enums;

import com.fasterxml.jackson.annotation.JsonCreator;

public enum OrderStatus {
    CREATED,
    PAID,
    SHIPPED,
    DELIVERED,
    CANCELED,
    PENDING,
    CANCELLED,
    CONFIRMED,
    SEPARATED;

    @JsonCreator
    public static OrderStatus fromValue(String value) {
        return valueOf(value.toUpperCase());
    }
}