package com.pubsub6.grupo.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pubsub6.grupo.dto.OrderDTO;
import com.pubsub6.grupo.dto.OrderResponseDTO;
import com.pubsub6.grupo.exception.OrderNotFoundException;
import com.pubsub6.grupo.mapper.OrderMapper;
import com.pubsub6.grupo.model.*;
import com.pubsub6.grupo.model.enums.OrderStatus;
import com.pubsub6.grupo.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository       orderRepository;
    private final CustomerRepository    customerRepository;
    private final SellerRepository      sellerRepository;
    private final CategoryRepository    categoryRepository;
    private final SubCategoryRepository subCategoryRepository;
    private final ObjectMapper          objectMapper;
    private final OrderMapper           orderMapper;

    @Transactional
    public void processOrder(String json) {
        OrderDTO dto = deserialize(json);

        if (orderRepository.existsByUuid(dto.uuid())) {
            log.debug("Pedido duplicado ignorado: {}", dto.uuid());
            return;
        }

        Order order = buildOrder(dto);
        orderRepository.save(order);
        log.info("Pedido persistido: {} | {} itens", order.getUuid(), order.getItems().size());
    }

    @Transactional
    public OrderResponseDTO findByUuid(String uuid) {
        return orderRepository.findByUuid(uuid)
                .map(orderMapper::toResponse)
                .orElseThrow(() -> new OrderNotFoundException(uuid));
    }

    @Transactional
    public Page<OrderResponseDTO> findAll(String status, Long customerId, Long productId, Pageable pageable) {
        var spec = OrderSpecification.withFilters(status, customerId, productId);
        return orderRepository.findAll(spec, pageable).map(orderMapper::toResponse);
    }

    private OrderDTO deserialize(String json) {
        try {
            return objectMapper.readValue(json, OrderDTO.class);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("JSON inválido", e);
        }
    }

    private Order buildOrder(OrderDTO dto) {
        Order order = new Order();
        order.setUuid(dto.uuid());
        order.setCreatedAt(dto.createdAt());
        order.setChannel(dto.channel());
        order.setStatus(OrderStatus.fromValue(dto.status()));

        order.setCustomer(findOrCreate(dto));
        order.setSeller(findOrCreateSeller(dto));

        order.setItems(dto.items().stream()
                .map(item -> buildItem(item, order))
                .toList());

        order.setShipment(orderMapper.toEntity(dto.shipment()));
        order.setPayment(orderMapper.toEntity(dto.payment()));
        order.setMetadata(orderMapper.toEntity(dto.metadata()));

        return order;
    }

    private Customer findOrCreate(OrderDTO dto) {
        return customerRepository.findById(dto.customer().id())
                .orElseGet(() -> customerRepository.save(orderMapper.toEntity(dto.customer())));
    }

    private Seller findOrCreateSeller(OrderDTO dto) {
        return sellerRepository.findById(dto.seller().id())
                .orElseGet(() -> sellerRepository.save(orderMapper.toEntity(dto.seller())));
    }

    private OrderItem buildItem(com.pubsub6.grupo.dto.OrderItemDTO dto, Order order) {
        SubCategory sub = subCategoryRepository
                .findById(dto.category().subCategory().id())
                .orElseGet(() -> subCategoryRepository.save(
                        new SubCategory(dto.category().subCategory().id(),
                                dto.category().subCategory().name())));

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
}
