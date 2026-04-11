package com.pubsub6.grupo.controller;

import com.pubsub6.grupo.dto.OrderResponseDTO;
import com.pubsub6.grupo.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @GetMapping("/{uuid}")
    public ResponseEntity<OrderResponseDTO> findByUuid(@PathVariable String uuid) {
        return ResponseEntity.ok(orderService.findByUuid(uuid));
    }

    @GetMapping
    public ResponseEntity<Page<OrderResponseDTO>> findAll(
            @RequestParam(required = false) String status,
            @RequestParam(required = false, name = "customer_id") Long customerId,
            @RequestParam(required = false, name = "product_id") Long productId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        return ResponseEntity.ok(orderService.findAll(status, customerId, productId, pageable));
    }

    @PostMapping("/import")
    public ResponseEntity<String> importOrder(@RequestBody String json) {
        orderService.processOrder(json);
        return ResponseEntity.ok("Pedido importado com sucesso");
    }
}
