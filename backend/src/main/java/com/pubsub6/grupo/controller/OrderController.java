package com.pubsub6.grupo.controller;

import com.pubsub6.grupo.dto.OrderResponseDTO;
import com.pubsub6.grupo.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Pedidos", description = "API de consulta de pedidos do marketplace")
@RestController
@RequestMapping("/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @Operation(summary = "Buscar pedido por UUID", description = "Retorna o pedido completo com totais calculados")
    @ApiResponse(responseCode = "200", description = "Pedido encontrado")
    @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    @GetMapping("/{uuid}")
    public ResponseEntity<OrderResponseDTO> findByUuid(
            @Parameter(description = "UUID do pedido", example = "b28ab819-c950-485b-8a4f-d1e022315a74")
            @PathVariable String uuid
    ) {
        return ResponseEntity.ok(orderService.findByUuid(uuid));
    }

    @Operation(summary = "Listar pedidos", description = "Retorna pedidos paginados com filtros opcionais")
    @GetMapping
    public ResponseEntity<Page<OrderResponseDTO>> findAll(
            @Parameter(description = "Filtrar por status", example = "PAID")
            @RequestParam(required = false) String status,

            @Parameter(description = "Filtrar por ID do cliente", example = "58706")
            @RequestParam(required = false, name = "customer_id") Long customerId,

            @Parameter(description = "Filtrar por ID do produto", example = "1190")
            @RequestParam(required = false, name = "product_id") Long productId,

            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        return ResponseEntity.ok(orderService.findAll(status, customerId, productId, pageable));
    }

    @Operation(summary = "Importar pedido", description = "Importa pedido via JSON (mesmo formato do Pub/Sub)")
    @ApiResponse(responseCode = "200", description = "Pedido importado com sucesso")
    @PostMapping("/import")
    public ResponseEntity<String> importOrder(@RequestBody String json) {
        orderService.processOrder(json);
        return ResponseEntity.ok("Pedido importado com sucesso");
    }
}
