package com.pubsub6.grupo.repository;

import com.pubsub6.grupo.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, String> {
}
