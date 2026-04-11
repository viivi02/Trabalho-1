package com.pubsub6.grupo.repository;

import com.pubsub6.grupo.model.Order;
import com.pubsub6.grupo.model.OrderItem;
import com.pubsub6.grupo.model.enums.OrderStatus;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import org.springframework.data.jpa.domain.Specification;

public final class OrderSpecification {

    private OrderSpecification() {}

    public static Specification<Order> hasStatus(String status) {
        return (root, query, cb) ->
                cb.equal(root.get("status"), OrderStatus.fromValue(status));
    }

    public static Specification<Order> hasCustomer(Long customerId) {
        return (root, query, cb) ->
                cb.equal(root.get("customer").get("id"), customerId);
    }

    public static Specification<Order> hasProduct(Long productId) {
        return (root, query, cb) -> {
            Join<Order, OrderItem> items = root.join("items", JoinType.INNER);
            return cb.equal(items.get("productId"), productId);
        };
    }

    public static Specification<Order> withFilters(String status, Long customerId, Long productId) {
        Specification<Order> spec = Specification.where((root, query, cb) -> cb.conjunction());

        if (status != null && !status.isBlank()) {
            spec = spec.and(hasStatus(status));
        }
        if (customerId != null) {
            spec = spec.and(hasCustomer(customerId));
        }
        if (productId != null) {
            spec = spec.and(hasProduct(productId));
        }
        return spec;
    }
}
