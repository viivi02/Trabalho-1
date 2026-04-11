package com.pubsub6.grupo.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "order_metadata")
public class OrderMetadata {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String source, userAgent, ipAddress;
}
