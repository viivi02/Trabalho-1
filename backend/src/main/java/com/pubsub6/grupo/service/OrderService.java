package com.pubsub6.grupo.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pubsub6.grupo.dto.*;
import com.pubsub6.grupo.model.*;
import com.pubsub6.grupo.model.enums.OrderStatus;
import com.pubsub6.grupo.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository       orderRepository;
    private final CustomerRepository    customerRepository;
    private final SellerRepository      sellerRepository;
    private final CategoryRepository    categoryRepository;
    private final SubCategoryRepository subCategoryRepository;
    private final ObjectMapper          objectMapper;

    @Transactional
    public void processOrder(String json) {
        OrderDTO dto;

        try {
            dto = objectMapper.readValue(json, OrderDTO.class);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("JSON inválido", e);
        }

        if (orderRepository.existsByUuid(dto.uuid())) {
            return;
        }

        Order order = new Order();
        order.setUuid(dto.uuid());
        order.setCreatedAt(dto.createdAt());
        order.setChannel(dto.channel());
        order.setStatus(OrderStatus.fromValue(dto.status()));

        Customer customer = customerRepository.findById(dto.customer().id())
                .orElseGet(() -> customerRepository.save(toCustomer(dto.customer())));
        order.setCustomer(customer);

        Seller seller = sellerRepository.findById(dto.seller().id())
                .orElseGet(() -> sellerRepository.save(toSeller(dto.seller())));
        order.setSeller(seller);

        order.setItems(dto.items().stream()
                .map(item -> toOrderItem(item, order))
                .toList());

        order.setShipment(toShipment(dto.shipment()));
        order.setPayment(toPayment(dto.payment()));
        order.setMetadata(toMetadata(dto.metadata()));

        orderRepository.save(order);
    }

    private OrderItem toOrderItem(OrderItemDTO dto, Order order) {
        SubCategory sub = subCategoryRepository
                .findById(dto.category().subCategory().id())
                .orElseGet(() -> subCategoryRepository.save(
                        new SubCategory(dto.category().subCategory().id(),
                                dto.category().subCategory().name())
                ));

        Category cat = categoryRepository
                .findById(dto.category().id())
                .orElseGet(() -> {
                    Category c = new Category();
                    c.setId(dto.category().id());
                    c.setName(dto.category().name());
                    c.setSubCategory(sub);
                    return categoryRepository.save(c);
                });

        OrderItem item = new OrderItem();
        item.setProductId(dto.productId());
        item.setProductName(dto.productName());
        item.setUnitPrice(dto.unitPrice());
        item.setQuantity(dto.quantity());
        item.setCategory(cat);
        item.setOrder(order);
        return item;
    }

    private Customer toCustomer(CustomerDTO d) {
        return new Customer(d.id(), d.name(), d.email(), d.document());
    }
    private Seller toSeller(SellerDTO d) {
        return new Seller(d.id(), d.name(), d.city(), d.state());
    }
    private Shipment toShipment(ShipmentDTO d) {
        return new Shipment(null, d.carrier(), d.service(), d.status(), d.trackingCode());
    }
    private Payment toPayment(PaymentDTO d) {
        return new Payment(null, d.method(), d.status(), d.transactionId());
    }
    private OrderMetadata toMetadata(OrderMetadataDTO d) {
        return new OrderMetadata(null, d.source(), d.userAgent(), d.ipAddress());
    }
}