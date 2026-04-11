# Apresentação - Projeto Mensageria

> Computação em Nuvem II - FATEC  
> Grupo 6 - Java / Spring Boot

---

## 1. O que o projeto faz

O sistema consome mensagens de pedidos publicadas em tempo real pelo professor via **Google Cloud Pub/Sub**, persiste em um banco **PostgreSQL**, e expõe uma **API REST** + **Dashboard Web** para consulta.

```
Professor (publica pedidos)
        ↓
   Google Cloud Pub/Sub (sub-grupo6)
        ↓
   Consumer (PubSubSubscriber)
        ↓
   PostgreSQL (persistência)
        ↓
   API REST (OrderController)
        ↓
   Dashboard / Swagger / Postman
```

---

## 2. Tecnologias

| Camada       | Tecnologia                         |
| ------------ | ---------------------------------- |
| Linguagem    | Java 21                            |
| Framework    | Spring Boot 4.0.5                  |
| Persistência | Spring Data JPA + Hibernate 7      |
| Banco        | PostgreSQL 15 (Docker)             |
| Mensageria   | Google Cloud Pub/Sub               |
| Docs API     | SpringDoc OpenAPI 3.0.2 (Swagger)  |
| Frontend     | HTML + CSS + JavaScript nativo     |

---

## 3. Banco de Dados

### DER

![DER](./database/dernuvemII.drawio.png)

### Tabelas (9 tabelas, requisito mínimo: pedido, cliente, produto, item_pedido)

| Tabela           | Função                              |
| ---------------- | ----------------------------------- |
| `orders`         | Pedidos (uuid, status, channel, indexed_at) |
| `customers`      | Clientes                            |
| `sellers`        | Vendedores                          |
| `order_items`    | Itens do pedido (qty, unit_price)   |
| `categories`     | Categorias                          |
| `sub_categories` | Subcategorias                       |
| `payments`       | Pagamento (method, transaction_id)  |
| `shipments`      | Envio (carrier, tracking_code)      |
| `order_metadata` | Metadados (source, ip, user_agent)  |

**indexed_at** → registra quando a mensagem foi persistida no banco (requisito do professor).

---

## 4. Consumer (Parte 1 do enunciado)

### Arquivos-chave

**`pubsub/PubSubConfig.java`** → Configura conexão com Pub/Sub
```java
// Conecta ao projeto GCP com credenciais do key.json
// Subscription: sub-grupo6
Subscriber.newBuilder(subscriptionName, subscriber.receiver())
    .setCredentialsProvider(() -> credentials)
    .build();
```

**`pubsub/PubSubSubscriber.java`** → Recebe e processa cada mensagem
```java
public MessageReceiver receiver() {
    return (message, consumer) -> {
        String json = message.getData().toStringUtf8();
        service.processOrder(json);   // persiste no banco
        consumer.ack();               // confirma recebimento
    };
}
```

**`service/OrderService.java`** → Lógica de persistência
```java
public void processOrder(String json) {
    OrderDTO dto = objectMapper.readValue(json, OrderDTO.class);

    if (orderRepository.existsByUuid(dto.uuid())) return;  // deduplicação

    // Cria Order + Customer + Seller + Items + Shipment + Payment + Metadata
    orderRepository.save(order);
}
```

### O que acontece quando uma mensagem chega?
1. Pub/Sub entrega JSON → `PubSubSubscriber`
2. Deserializa com Jackson → `OrderDTO` (record)
3. Verifica duplicata por UUID
4. Find-or-create: Customer, Seller, Category, SubCategory
5. Monta entity `Order` com todos os relacionamentos
6. Salva no PostgreSQL (cascade)
7. Dá `ack()` → Pub/Sub não reenvia

---

## 5. API REST (Parte 2 do enunciado)

### Arquivo-chave: `controller/OrderController.java`

### Endpoints

| Método | Rota               | Descrição                       |
| ------ | ------------------ | ------------------------------- |
| GET    | `/orders`          | Lista paginada com filtros      |
| GET    | `/orders/{uuid}`   | Detalhe por UUID                |
| POST   | `/orders/import`   | Import manual (mesmo JSON)      |

### Filtros obrigatórios (conforme enunciado)

| Filtro         | Exemplo                              |
| -------------- | ------------------------------------ |
| UUID           | `GET /orders/b28ab819-c950-...`      |
| ID do cliente  | `GET /orders?customer_id=58706`      |
| ID do produto  | `GET /orders?product_id=1190`        |
| Status         | `GET /orders?status=PAID`            |

### Paginação e ordenação
```
GET /orders?page=0&size=10&sort=createdAt,desc
```

### Cálculo dinâmico de totais (requisito do professor)

Os totais NÃO são armazenados no banco. São calculados pela API:

```java
// item.total = unit_price × quantity
BigDecimal itemTotal = item.getUnitPrice()
    .multiply(BigDecimal.valueOf(item.getQuantity()));

// order.total = soma de todos os item.total
BigDecimal total = itemDtos.stream()
    .map(OrderItemResponseDTO::total)
    .reduce(BigDecimal.ZERO, BigDecimal::add);
```

### Exemplo de resposta (contrato conforme payload do professor)

```json
{
  "uuid": "b28ab819-c950-485b-8a4f-d1e022315a74",
  "created_at": "2026-03-26T19:27:47",
  "channel": "phone",
  "status": "PENDING",
  "total": 83399.00,
  "customer": {
    "id": 58706,
    "name": "Maria Oliveira",
    "email": "customer58706@email.com",
    "document": "719.688.520-13"
  },
  "seller": {
    "id": 85,
    "name": "Mega Eletrônicos",
    "city": "Rio de Janeiro",
    "state": "MG"
  },
  "items": [
    {
      "product_id": 1190,
      "product_name": "Telefone com fio",
      "unit_price": 1661.00,
      "quantity": 3,
      "category": {
        "id": "GAME",
        "name": "Category TV",
        "sub_category": { "id": "MONITOR", "name": "SubCategory TABLET" }
      },
      "total": 4983.00
    }
  ],
  "shipment": {
    "carrier": "FedEx",
    "service": "SEDEX",
    "status": "in_transit",
    "tracking_code": "BR979943220"
  },
  "payment": {
    "method": "pix",
    "status": "approved",
    "transaction_id": "pay_221684238"
  },
  "metadata": {
    "source": "website",
    "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0...)",
    "ip_address": "10.50.96.184"
  },
  "indexed_at": "2026-04-11T02:06:01"
}
```

---

## 6. Frontend Dashboard

**Arquivo:** `src/main/resources/static/index.html`

Servido pelo próprio Spring Boot em `http://localhost:8080`.

### Funcionalidades
- Tabela de pedidos com UUID, cliente, status, canal, total e data
- Filtros por status, ID do cliente e ID do produto
- Paginação completa
- Modal com detalhes ao clicar (cliente, vendedor, itens, envio, pagamento, metadata)
- Link direto para Swagger UI

---

## 7. Demonstração (passo a passo)

### Subir o ambiente
```bash
cd backend
docker-compose up -d          # PostgreSQL
./mvnw spring-boot:run        # Aplicação
```

### Verificar consumer
No log deve aparecer:
```
Criando subscriber para serjava-demo/sub-grupo6 com credenciais de ../key.json
Subscriber CONECTADO e recebendo mensagens
```

### Testar API (Postman ou Swagger)

**1. Importar pedido de teste:**
```
POST http://localhost:8080/orders/import
Content-Type: application/json
Body: { "uuid": "test-001", "created_at": "2026-04-10T10:00:00Z", ... }
```

**2. Listar pedidos:**
```
GET http://localhost:8080/orders
```

**3. Filtrar por status:**
```
GET http://localhost:8080/orders?status=PENDING
```

**4. Buscar por UUID:**
```
GET http://localhost:8080/orders/test-001
```

**5. Filtrar por cliente:**
```
GET http://localhost:8080/orders?customer_id=58706
```

### Acessar

| O que         | URL                                  |
| ------------- | ------------------------------------ |
| Dashboard     | http://localhost:8080                 |
| Swagger UI    | http://localhost:8080/swagger-ui.html |
| API           | http://localhost:8080/orders          |

---

## 8. Checklist dos requisitos

| Requisito do Professor                          | Status |
| ----------------------------------------------- | ------ |
| Consumer lê mensagens do Pub/Sub                | OK     |
| Persistência em banco relacional                | OK     |
| Tabelas: pedido, cliente, produto, item_pedido  | OK (+ 5 extras) |
| Registra hora de indexação (indexed_at)          | OK     |
| Linguagem Java                                  | OK     |
| API GET /orders com paginação                   | OK     |
| Ordenação por data                              | OK     |
| Contrato conforme payload do professor          | OK     |
| Arquitetura RESTful                             | OK     |
| Filtro por UUID (/orders/{uuid})                | OK     |
| Filtro por ID cliente                           | OK     |
| Filtro por ID produto                           | OK     |
| Filtro por status                               | OK     |
| Cálculo dinâmico: total do pedido               | OK     |
| Cálculo dinâmico: total de cada item            | OK     |
| DER do banco de dados                           | OK     |
| Fontes no git                                   | OK     |
