package com.pubsub6.grupo.repository;

import com.pubsub6.grupo.model.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomerRepository extends JpaRepository<Customer, Long> {
}
