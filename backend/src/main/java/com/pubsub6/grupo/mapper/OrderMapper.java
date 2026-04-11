package com.pubsub6.grupo.mapper;

import com.pubsub6.grupo.dto.*;
import com.pubsub6.grupo.model.*;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Component
public class OrderMapper {

    public OrderResponseDTO toResponse(Order order) {
        List<OrderItemResponseDTO> items = order.getItems().stream()
                .map(this::toItemResponse)
                .toList();

        BigDecimal total = items.stream()
                .map(OrderItemResponseDTO::total)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new OrderResponseDTO(
                order.getUuid(),
                order.getCreatedAt(),
                order.getChannel(),
                order.getStatus().name(),
                toCustomerDTO(order.getCustomer()),
                toSellerDTO(order.getSeller()),
                items,
                toShipmentDTO(order.getShipment()),
                toPaymentDTO(order.getPayment()),
                toMetadataDTO(order.getMetadata()),
                order.getIndexedAt(),
                total
        );
    }

    public OrderItemResponseDTO toItemResponse(OrderItem item) {
        BigDecimal itemTotal = item.getUnitPrice()
                .multiply(BigDecimal.valueOf(item.getQuantity()));

        return new OrderItemResponseDTO(
                item.getProductId(),
                item.getProductName(),
                item.getUnitPrice(),
                item.getQuantity(),
                toCategoryDTO(item.getCategory()),
                itemTotal
        );
    }

    public Customer toEntity(CustomerDTO dto) {
        return new Customer(dto.id(), dto.name(), dto.email(), dto.document());
    }

    public Seller toEntity(SellerDTO dto) {
        return new Seller(dto.id(), dto.name(), dto.city(), dto.state());
    }

    public Shipment toEntity(ShipmentDTO dto) {
        return new Shipment(null, dto.carrier(), dto.service(), dto.status(), dto.trackingCode());
    }

    public Payment toEntity(PaymentDTO dto) {
        return new Payment(null, dto.method(), dto.status(), dto.transactionId());
    }

    public OrderMetadata toEntity(OrderMetadataDTO dto) {
        return new OrderMetadata(null, dto.source(), dto.userAgent(), dto.ipAddress());
    }

    private CustomerDTO toCustomerDTO(Customer c) {
        return new CustomerDTO(c.getId(), c.getName(), c.getEmail(), c.getDocument());
    }

    private SellerDTO toSellerDTO(Seller s) {
        return new SellerDTO(s.getId(), s.getName(), s.getCity(), s.getState());
    }

    private ShipmentDTO toShipmentDTO(Shipment s) {
        return new ShipmentDTO(s.getCarrier(), s.getService(), s.getStatus(), s.getTrackingCode());
    }

    private PaymentDTO toPaymentDTO(Payment p) {
        return new PaymentDTO(p.getMethod(), p.getStatus(), p.getTransactionId());
    }

    private OrderMetadataDTO toMetadataDTO(OrderMetadata m) {
        return new OrderMetadataDTO(m.getSource(), m.getUserAgent(), m.getIpAddress());
    }

    private CategoryDTO toCategoryDTO(Category cat) {
        if (cat == null) return null;
        SubCategoryDTO sub = cat.getSubCategory() != null
                ? new SubCategoryDTO(cat.getSubCategory().getId(), cat.getSubCategory().getName())
                : null;
        return new CategoryDTO(cat.getId(), cat.getName(), sub);
    }
}
