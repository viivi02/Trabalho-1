package com.pubsub6.grupo.repository;

import com.pubsub6.grupo.model.Order;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long>, JpaSpecificationExecutor<Order> {

    boolean existsByUuid(String uuid);

    @EntityGraph(attributePaths = {"customer", "seller", "items", "items.category", "items.category.subCategory", "shipment", "payment", "metadata"})
    Optional<Order> findByUuid(String uuid);
}
