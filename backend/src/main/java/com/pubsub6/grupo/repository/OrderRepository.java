package com.pubsub6.grupo.repository;

import com.pubsub6.grupo.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {

    boolean existsByUuid(String uuid);
}
