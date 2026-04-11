# Guia de Apresentacao ao Vivo - Projeto Mensageria

> Use este guia passo a passo durante a demonstracao para o professor.
> Cada item corresponde a um requisito do enunciado oficial.

---

## 0. Preparacao (antes de comecar)

```bash
cd backend
docker-compose up -d          # Sobe o PostgreSQL
./mvnw spring-boot:run        # Sobe a aplicacao
```

Abrir:
- **Postman** (para testar API)
- **DBeaver** conectado em `localhost:5432 / banco_pubsub / postgres / postgres`
- **Navegador** em `http://localhost:8080` (Dashboard)
- **Navegador** em `http://localhost:8080/swagger-ui.html` (Swagger)

Importar dados de teste no Postman:

```
POST http://localhost:8080/orders/import
Content-Type: application/json
```

Body pedido 1:
```json
{"uuid":"demo-001","created_at":"2026-04-10T10:00:00Z","channel":"mobile_app","status":"paid","customer":{"id":100,"name":"Joao Silva","email":"joao@email.com","document":"123.456.789-00"},"seller":{"id":10,"name":"Tech Store","city":"Sao Paulo","state":"SP"},"items":[{"id":1,"product_id":5001,"product_name":"Notebook Pro","unit_price":4500.00,"quantity":1,"category":{"id":"COMP","name":"Computadores","sub_category":{"id":"LAPTOP","name":"Laptops"}}},{"id":2,"product_id":6001,"product_name":"Mouse Gamer","unit_price":250.00,"quantity":2,"category":{"id":"ACC","name":"Acessorios","sub_category":{"id":"MOUSE","name":"Mouses"}}}],"shipment":{"carrier":"Correios","service":"SEDEX","status":"shipped","tracking_code":"BR111222333"},"payment":{"method":"credit_card","status":"approved","transaction_id":"pay_111"},"metadata":{"source":"app","user_agent":"Chrome/120","ip_address":"192.168.1.1"}}
```

Body pedido 2:
```json
{"uuid":"demo-002","created_at":"2026-04-11T08:30:00Z","channel":"website","status":"shipped","customer":{"id":200,"name":"Ana Costa","email":"ana@email.com","document":"987.654.321-00"},"seller":{"id":20,"name":"Mega Shop","city":"Curitiba","state":"PR"},"items":[{"id":1,"product_id":5001,"product_name":"Notebook Pro","unit_price":4500.00,"quantity":2,"category":{"id":"COMP","name":"Computadores","sub_category":{"id":"LAPTOP","name":"Laptops"}}}],"shipment":{"carrier":"FedEx","service":"Express","status":"in_transit","tracking_code":"BR444555666"},"payment":{"method":"pix","status":"approved","transaction_id":"pay_222"},"metadata":{"source":"website","user_agent":"Firefox/115","ip_address":"10.0.0.5"}}
```

Body pedido 3:
```json
{"uuid":"demo-003","created_at":"2026-04-09T15:00:00Z","channel":"phone","status":"delivered","customer":{"id":100,"name":"Joao Silva","email":"joao@email.com","document":"123.456.789-00"},"seller":{"id":10,"name":"Tech Store","city":"Sao Paulo","state":"SP"},"items":[{"id":1,"product_id":7001,"product_name":"Teclado Mecanico","unit_price":350.00,"quantity":1,"category":{"id":"ACC","name":"Acessorios","sub_category":{"id":"KEYBOARD","name":"Teclados"}}}],"shipment":{"carrier":"Correios","service":"PAC","status":"delivered","tracking_code":"BR777888999"},"payment":{"method":"boleto","status":"approved","transaction_id":"pay_333"},"metadata":{"source":"app","user_agent":"Safari/17","ip_address":"172.16.0.10"}}
```

---

## ENTREGAVEIS

### Demonstracao do projeto funcionando
> Mostrar o Dashboard no navegador (`http://localhost:8080`) com os pedidos listados.

### DER do Banco de Dados
> Abrir o arquivo `database/dernuvemII.drawio.png` ou mostrar no README.

### Fontes do projeto no git
> Abrir o repositorio no GitHub: `https://github.com/viivi02/Trabalho-1`

### Commit de todos os membros
> Rodar `git log --oneline` e mostrar os commits de cada membro.

---

## PARTE 1 - CONSUMER

### 1.1 "Implemente um consumidor para ler os dados de Pedidos"

**Onde esta no codigo:**

- `pubsub/PubSubConfig.java` - Configura conexao com Google Cloud Pub/Sub
- `pubsub/PubSubSubscriber.java` - Recebe cada mensagem e chama o service

**Como funciona:**
O `PubSubConfig` cria um `Subscriber` que conecta na subscription `sub-grupo6` do projeto GCP `serjava-demo` usando as credenciais do `key.json`. Quando uma mensagem chega, o `PubSubSubscriber.receiver()` extrai o JSON e chama `orderService.processOrder(json)`.

**Mostrar no log do terminal:**
```
Conectando ao Pub/Sub: serjava-demo/sub-grupo6
Subscriber conectado e aguardando mensagens
```

---

### 1.2 "Esses dados devem ser persistidos numa base relacional"

**Onde esta no codigo:**

- `service/OrderService.java` metodo `processOrder()` (linha 33-43)
- Persiste via `orderRepository.save(order)` no PostgreSQL

**Demonstrar no DBeaver:**
```sql
SELECT id, uuid, status, channel, created_at, indexed_at FROM orders;
```

---

### 1.3 "Devera ter minimamente as tabelas: pedido, cliente, produto, item_pedido"

**Demonstrar no DBeaver:**
```sql
-- Mostra todas as 9 tabelas (requisito minimo era 4)
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
```

Resultado esperado:

| Tabela Exigida | Nossa Tabela     |
| -------------- | ---------------- |
| pedido         | `orders`         |
| cliente        | `customers`      |
| produto        | (dentro de `order_items` com product_id e product_name) |
| item_pedido    | `order_items`    |
| *(extras)*     | `sellers`, `categories`, `sub_categories`, `payments`, `shipments`, `order_metadata` |

**Demonstrar no DBeaver:**
```sql
SELECT id, name, email, document FROM customers;
SELECT id, uuid, status, channel FROM orders;
SELECT id, product_name, unit_price, quantity FROM order_items;
SELECT id, name, city, state FROM sellers;
```

---

### 1.4 "Registre a hora que a mensagem foi indexada na base de dados"

**Onde esta no codigo:**

- `model/Order.java` linhas 58-64:
```java
@Column(name = "indexed_at", updatable = false)
private LocalDateTime indexedAt;

@PrePersist
public void prePersist() {
    this.indexedAt = LocalDateTime.now();
}
```

O `@PrePersist` grava automaticamente a hora exata em que o pedido foi salvo no banco.

**Demonstrar no DBeaver:**
```sql
-- Mostra created_at (hora do pedido) vs indexed_at (hora da persistencia)
SELECT uuid,
       created_at  AS "hora do pedido",
       indexed_at  AS "hora da indexacao",
       (indexed_at - created_at) AS "diferenca"
FROM orders;
```

---

### 1.5 "Use a linguagem definida na divisao dos grupos"

> **Java 21** com **Spring Boot 4.0.5**
> Mostrar no `pom.xml` a tag `<java.version>21</java.version>` e o parent Spring Boot 4.0.5.

---

## PARTE 2 - API REST

### 2.1 "Implemente uma rota de API que permita consultar os pedidos"

**Onde esta no codigo:**

- `controller/OrderController.java` - define os endpoints REST
- `service/OrderService.java` - logica de consulta
- `repository/OrderRepository.java` - queries JPA

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders
```

---

### 2.2 "Paginacao na API"

**Onde esta no codigo:**

- `OrderController.java` linha 48:
```java
@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
```

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders?page=0&size=2
```

Mostrar na resposta o objeto `page`:
```json
{
  "page": {
    "size": 2,
    "number": 0,
    "totalElements": 3,
    "totalPages": 2
  }
}
```

Depois:
```
GET http://localhost:8080/orders?page=1&size=2
```

Mostrar que retorna o pedido restante na pagina 2.

---

### 2.3 "Ordenacao por data"

**Onde esta no codigo:**

- `OrderController.java` - default `sort = "createdAt", direction = Sort.Direction.DESC`

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders?sort=createdAt,asc
GET http://localhost:8080/orders?sort=createdAt,desc
```

Mostrar que a ordem dos pedidos muda.

---

### 2.4 "Endpoint GET /orders"

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders
```

---

### 2.5 "Retorno da API deve ter o contrato conforme modelo de payload"

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders/demo-001
```

Comparar a resposta com o payload do enunciado campo por campo:
- `uuid` ✓
- `created_at` ✓
- `channel` ✓
- `total` ✓ (calculado)
- `status` ✓
- `customer` { id, name, email, document } ✓
- `seller` { id, name, city, state } ✓
- `items[]` { product_id, product_name, unit_price, quantity, category { id, name, sub_category }, total } ✓
- `shipment` { carrier, service, status, tracking_code } ✓
- `payment` { method, status, transaction_id } ✓
- `metadata` { source, user_agent, ip_address } ✓
- `indexed_at` ✓ (campo adicional nosso)

---

### 2.6 "Atente-se a arquitetura RESTFull"

**Onde esta no codigo:**

- `@RestController` + `@RequestMapping("/orders")` - recurso padrao REST
- Verbos HTTP corretos: `GET` para consulta, `POST` para criacao
- Status codes: `200 OK`, `404 Not Found` (via `ProblemDetail` RFC 7807)
- Paginacao via query params
- Recurso identificado por UUID na URI

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders/uuid-que-nao-existe
```

Mostrar a resposta 404 estruturada:
```json
{
  "type": "about:blank",
  "title": "Pedido nao encontrado",
  "status": 404,
  "detail": "Pedido nao encontrado: uuid-que-nao-existe"
}
```

---

### 2.7 "Status do pedido (created, paid, shipped, delivered, canceled)"

**Onde esta no codigo:**

- `model/enums/OrderStatus.java`:
```java
public enum OrderStatus {
    CREATED, PAID, SHIPPED, DELIVERED, CANCELED,
    PENDING, CANCELLED, CONFIRMED, SEPARATED;
}
```

**Demonstrar no DBeaver:**
```sql
SELECT status, COUNT(*) as quantidade FROM orders GROUP BY status;
```

---

### 2.8 FILTROS OBRIGATORIOS

#### Filtro por UUID: /orders/{uuid}

**Onde esta no codigo:**

- `OrderController.java` linha 28: `@GetMapping("/{uuid}")`
- `OrderRepository.java`: `findByUuid()` com `@EntityGraph`

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders/demo-001
```

---

#### Filtro por ID do cliente: /orders?codigoCliente=49494

**Onde esta no codigo:**

- `OrderController.java` linha 43: `@RequestParam(name = "customer_id") Long customerId`
- `OrderSpecification.java` metodo `hasCustomer()`:
```java
public static Specification<Order> hasCustomer(Long customerId) {
    return (root, query, cb) ->
            cb.equal(root.get("customer").get("id"), customerId);
}
```

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders?customer_id=100
```

Deve retornar apenas os pedidos do Joao Silva (id=100): demo-001 e demo-003.

```
GET http://localhost:8080/orders?customer_id=200
```

Deve retornar apenas o pedido da Ana Costa (id=200): demo-002.

---

#### Filtro por ID do produto

**Onde esta no codigo:**

- `OrderController.java` linha 46: `@RequestParam(name = "product_id") Long productId`
- `OrderSpecification.java` metodo `hasProduct()`:
```java
public static Specification<Order> hasProduct(Long productId) {
    return (root, query, cb) -> {
        Join<Order, OrderItem> items = root.join("items", JoinType.INNER);
        return cb.equal(items.get("productId"), productId);
    };
}
```

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders?product_id=5001
```

Deve retornar demo-001 e demo-002 (ambos tem Notebook Pro, product_id 5001).

```
GET http://localhost:8080/orders?product_id=7001
```

Deve retornar apenas demo-003 (Teclado Mecanico).

---

#### Filtro por status do pedido

**Onde esta no codigo:**

- `OrderController.java` linha 40: `@RequestParam(required = false) String status`
- `OrderSpecification.java` metodo `hasStatus()`

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders?status=PAID
```

Deve retornar apenas demo-001.

```
GET http://localhost:8080/orders?status=SHIPPED
```

Deve retornar apenas demo-002.

```
GET http://localhost:8080/orders?status=DELIVERED
```

Deve retornar apenas demo-003.

---

#### Filtros combinados

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders?customer_id=100&status=PAID
```

Deve retornar apenas demo-001 (Joao Silva com status PAID).

---

### 2.9 REGRAS DA RESPOSTA

#### "Calcular dinamicamente: valor total do pedido"

**Onde esta no codigo:**

- `mapper/OrderMapper.java` linhas 18-20:
```java
BigDecimal total = items.stream()
    .map(OrderItemResponseDTO::total)
    .reduce(BigDecimal.ZERO, BigDecimal::add);
```

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders/demo-001
```

Verificar: `total = 5000.00` (Notebook 4500x1 + Mouse 250x2 = 4500 + 500 = 5000)

**Provar que NAO esta no banco (DBeaver):**
```sql
-- A coluna 'total' NAO existe na tabela orders
SELECT column_name FROM information_schema.columns WHERE table_name = 'orders';
```

---

#### "Calcular dinamicamente: valor total de cada item"

**Onde esta no codigo:**

- `mapper/OrderMapper.java` linhas 39-40:
```java
BigDecimal itemTotal = item.getUnitPrice()
    .multiply(BigDecimal.valueOf(item.getQuantity()));
```

**Demonstrar no Postman:**
```
GET http://localhost:8080/orders/demo-001
```

Verificar nos items:
- Notebook Pro: `unit_price: 4500, quantity: 1, total: 4500`
- Mouse Gamer: `unit_price: 250, quantity: 2, total: 500`

**Provar que NAO esta no banco (DBeaver):**
```sql
-- Calcular no SQL pra comparar com a API
SELECT product_name, unit_price, quantity, (unit_price * quantity) AS total_calculado
FROM order_items;
```

---

## BONUS - DEMONSTRAR VISUALMENTE

### Dashboard Frontend
> Abrir `http://localhost:8080` e mostrar:
> 1. Lista de pedidos com totais
> 2. Filtros funcionando (status, cliente, produto)
> 3. Clicar em um pedido e mostrar o modal com todos os detalhes
> 4. Paginacao funcionando

### Swagger UI
> Abrir `http://localhost:8080/swagger-ui.html` e mostrar:
> 1. Documentacao automatica dos endpoints
> 2. Testar um GET /orders direto pelo Swagger

### Estrutura do Projeto
> Mostrar a arvore de pastas organizada:
> - `backend/` - API + Consumer (Java/Spring Boot)
> - `frontend/` - Dashboard (HTML/CSS/JS)
> - `database/` - DER + Scripts SQL

---

## QUERIES UTEIS PARA DBEAVER (ter abertas em abas)

```sql
-- Aba 1: Visao geral dos pedidos
SELECT id, uuid, status, channel, created_at, indexed_at FROM orders;

-- Aba 2: Clientes
SELECT id, name, email, document FROM customers;

-- Aba 3: Itens com total calculado
SELECT oi.product_name, oi.unit_price, oi.quantity,
       (oi.unit_price * oi.quantity) AS total_item
FROM order_items oi;

-- Aba 4: Total por pedido (provar calculo dinamico)
SELECT o.uuid, o.status,
       SUM(oi.unit_price * oi.quantity) AS total_pedido
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.uuid, o.status;

-- Aba 5: indexed_at (rastreabilidade)
SELECT uuid,
       created_at  AS "hora do pedido",
       indexed_at  AS "hora da indexacao"
FROM orders;

-- Aba 6: Todas as tabelas
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;
```
