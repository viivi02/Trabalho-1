package com.pubsub6.grupo.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pubsub6.grupo.dto.*;
import com.pubsub6.grupo.exception.OrderNotFoundException;
import com.pubsub6.grupo.model.*;
import com.pubsub6.grupo.model.enums.OrderStatus;
import com.pubsub6.grupo.repository.*;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository       orderRepository;
    private final CustomerRepository    customerRepository;
    private final SellerRepository      sellerRepository;
    private final CategoryRepository    categoryRepository;
    private final SubCategoryRepository subCategoryRepository;
    private final ObjectMapper          objectMapper;

    // ── Consumer (existente) ──

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

    // ── API (consultas) ──

    @Transactional
    public OrderResponseDTO findByUuid(String uuid) {
        Order order = orderRepository.findByUuid(uuid)
                .orElseThrow(() -> new OrderNotFoundException(uuid));
        return toResponseDTO(order);
    }

    @Transactional
    public Page<OrderResponseDTO> findAll(String status, Long customerId, Long productId, Pageable pageable) {
        Specification<Order> spec = buildSpec(status, customerId, productId);
        return orderRepository.findAll(spec, pageable).map(this::toResponseDTO);
    }

    // ── Specifications ──

    private Specification<Order> buildSpec(String status, Long customerId, Long productId) {
        List<Specification<Order>> specs = new ArrayList<>();

        if (status != null && !status.isBlank()) {
            specs.add((root, query, cb) ->
                    cb.equal(root.get("status"), OrderStatus.fromValue(status)));
        }
        if (customerId != null) {
            specs.add((root, query, cb) ->
                    cb.equal(root.get("customer").get("id"), customerId));
        }
        if (productId != null) {
            specs.add((root, query, cb) -> {
                Join<Order, OrderItem> items = root.join("items", JoinType.INNER);
                return cb.equal(items.get("productId"), productId);
            });
        }

        return specs.stream().reduce(Specification::and).orElse((root, query, cb) -> cb.conjunction());
    }

    // ── Conversão Entity → Response DTO ──

    private OrderResponseDTO toResponseDTO(Order order) {
        List<OrderItemResponseDTO> itemDtos = order.getItems().stream()
                .map(this::toItemResponseDTO)
                .toList();

        BigDecimal total = itemDtos.stream()
                .map(OrderItemResponseDTO::total)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new OrderResponseDTO(
                order.getUuid(),
                order.getCreatedAt(),
                order.getChannel(),
                order.getStatus().name(),
                new CustomerDTO(
                        order.getCustomer().getId(),
                        order.getCustomer().getName(),
                        order.getCustomer().getEmail(),
                        order.getCustomer().getDocument()),
                new SellerDTO(
                        order.getSeller().getId(),
                        order.getSeller().getName(),
                        order.getSeller().getCity(),
                        order.getSeller().getState()),
                itemDtos,
                new ShipmentDTO(
                        order.getShipment().getCarrier(),
                        order.getShipment().getService(),
                        order.getShipment().getStatus(),
                        order.getShipment().getTrackingCode()),
                new PaymentDTO(
                        order.getPayment().getMethod(),
                        order.getPayment().getStatus(),
                        order.getPayment().getTransactionId()),
                new OrderMetadataDTO(
                        order.getMetadata().getSource(),
                        order.getMetadata().getUserAgent(),
                        order.getMetadata().getIpAddress()),
                order.getIndexedAt(),
                total
        );
    }

    private OrderItemResponseDTO toItemResponseDTO(OrderItem item) {
        BigDecimal itemTotal = item.getUnitPrice()
                .multiply(BigDecimal.valueOf(item.getQuantity()));

        CategoryDTO catDto = null;
        if (item.getCategory() != null) {
            SubCategoryDTO subDto = null;
            if (item.getCategory().getSubCategory() != null) {
                SubCategory sub = item.getCategory().getSubCategory();
                subDto = new SubCategoryDTO(sub.getId(), sub.getName());
            }
            catDto = new CategoryDTO(
                    item.getCategory().getId(),
                    item.getCategory().getName(),
                    subDto);
        }

        return new OrderItemResponseDTO(
                item.getProductId(),
                item.getProductName(),
                item.getUnitPrice(),
                item.getQuantity(),
                catDto,
                itemTotal
        );
    }

    // ── Conversão DTO → Entity (consumer) ──

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