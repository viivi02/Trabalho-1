# Documentacao Completa da API (`api/`)

Este documento explica a API em nivel macro e micro (linha a linha dos arquivos principais), para voce conseguir responder perguntas tecnicas do professor com seguranca.

---

## 1) Objetivo da API

A API em `api/` serve para **consultar pedidos ja persistidos no PostgreSQL** (gravados pelo consumer Java), com:

- listagem paginada (`GET /orders`)
- filtros (`codigoCliente`, `productId`, `status`)
- ordenacao por data (`sort=asc|desc`)
- consulta por UUID (`GET /orders/:uuid`)
- calculo dinamico de totais (total do pedido e total de cada item)

---

## 2) Arquitetura (camadas)

Estrutura atual:

- `src/server.js`: sobe o servidor HTTP
- `src/app.js`: configura middlewares e rotas
- `src/routes/orderRoutes.js`: mapeia endpoints
- `src/controllers/orderController.js`: camada HTTP (req/res)
- `src/services/orderService.js`: regra de entrada (parse/sanitizacao)
- `src/repositories/orderRepository.js`: acesso ao banco + montagem de payload
- `src/config/database.js`: conexao PostgreSQL (`pg`)
- `src/middleware/asyncHandler.js`: captura erro assinc
- `src/middleware/errorHandler.js`: tratamento global de erro

Fluxo de uma requisicao:

`HTTP -> Route -> Controller -> Service -> Repository -> PostgreSQL -> Repository -> Controller -> Response JSON`

---

## 3) Dependencias e runtime

Arquivo: `package.json`

- `express`: framework HTTP
- `pg`: driver PostgreSQL
- `cors`: habilita chamadas cross-origin (Flutter/web local)

Scripts:

- `npm run dev`: `node --watch src/server.js`
- `npm start`: `node src/server.js`

---

## 4) Banco de dados: onde a API consome

Arquivo: `src/config/database.js`

- cria `Pool` do `pg` com variaveis de ambiente:
  - `DB_HOST` (default `localhost`)
  - `DB_PORT` (default `5432`)
  - `DB_NAME` (default `banco_pubsub`)
  - `DB_USER` (default `postgres`)
  - `DB_PASSWORD` (default `postgres`)

As queries sao feitas no repository via `pool.query(...)`.

---

## 5) Endpoints e contrato

## `GET /orders`

Query params suportados:

- `page`: pagina (default 0)
- `size`: tamanho da pagina (default 20, max 100)
- `sort`: `asc` ou `desc` (default `desc`)
- `codigoCliente`: filtra por `orders.customer_id`
- `productId`: filtra pedidos que contenham item com esse produto
- `status`: filtra por status (`CREATED`, `PAID`, etc.)

Resposta:

```json
{
  "content": [/* pedidos */],
  "page": 0,
  "size": 20,
  "totalElements": 123,
  "totalPages": 7
}
```

## `GET /orders/:uuid`

- Busca um unico pedido por UUID.
- Se nao existe: `404 {"error":"Order not found"}`.

---

## 6) Explicacao linha a linha (arquivos principais)

## 6.1 `src/server.js`

- `L1`: importa o app Express pronto de `app.js`.
- `L3`: define porta via `PORT` ou default `3000`.
- `L5-L7`: inicia servidor HTTP e loga URL.

Responsabilidade: **apenas bootstrap do servidor**.

---

## 6.2 `src/app.js`

- `L1-L4`: importa Express, CORS, rotas e error middleware.
- `L6`: instancia o app.
- `L8`: `app.use(cors())` libera CORS.
- `L9`: `app.use(express.json())` parseia body JSON.
- `L11`: monta modulo de pedidos no prefixo `/orders`.
- `L13`: ultimo middleware: tratamento global de erro.
- `L15`: exporta app para `server.js`.

Responsabilidade: **pipeline HTTP** (middlewares + rotas + erro).

---

## 6.3 `src/routes/orderRoutes.js`

- `L1`: cria `Router` isolado.
- `L2`: importa controller.
- `L3`: importa `asyncHandler`.
- `L7`: rota `GET /orders` -> `orderController.list`.
- `L8`: rota `GET /orders/:uuid` -> `orderController.getByUuid`.

Detalhe importante: o `asyncHandler(...)` evita `try/catch` em toda rota.

---

## 6.4 `src/controllers/orderController.js`

- `L1`: usa service, nao acessa DB direto.
- `list(req,res)`:
  - `L4`: envia `req.query` para service.
  - `L5`: responde JSON pronto.
- `getByUuid(req,res)`:
  - `L9`: busca pelo `req.params.uuid`.
  - `L10-L12`: se null -> 404.
  - `L13`: se encontrou -> JSON.

Responsabilidade: **traduzir entrada/saida HTTP**.

---

## 6.5 `src/services/orderService.js`

Este arquivo concentra validacao leve e normalizacao de query params.

- `parseOptionalInt(value)`:
  - vazio/undefined/null -> `null`
  - converte com `Number(value)`
  - se nao for numero finito -> `null`
- `parseListQuery(query)`:
  - `page`: minimo 0
  - `size`: entre 1 e 100
  - `sort`: somente `asc`; qualquer outro vira `desc`
  - `codigoCliente` e `productId`: viram inteiros opcionais
  - `status`: trim; vazio vira `null`
- `listOrders(query)`:
  - converte params para formato interno e chama repository.
- `getOrderByUuid(uuid)`:
  - trim do UUID
  - se vazio, retorna `null`
  - senao delega ao repository

Responsabilidade: **regra de entrada** (sanitizacao).

---

## 6.6 `src/repositories/orderRepository.js` (core de dados)

Aqui esta o funcionamento mais importante da API.

### `findOrders(...)`

- `L4-L6`: prepara arrays de SQL dinamico:
  - `conditions` = clausulas `WHERE`
  - `values` = parametros (`$1`, `$2`, ...)
  - `paramIndex` = contador de placeholders
- `L8-L11`: filtro por cliente (`o.customer_id = $n`)
- `L13-L16`: filtro por status (`o.status = $n` em uppercase)
- `L18-L23`: filtro por produto com subquery `EXISTS`
  - garante que o pedido tenha item com `oi.product_id = $n`
- `L25`: monta `where` final
- `L26`: define direcao `ASC`/`DESC`
- `L27`: calcula `offset = page * size`

#### Contagem para paginacao

- `L29-L31`: `SELECT COUNT(*) FROM orders o ...`
  - retorna `totalElements`

#### Query principal

- `L33-L41`: seleciona pedidos da pagina atual com `LIMIT/OFFSET`
- `L42`: adiciona `size` e `offset` no array de valores
- `L44`: executa query
- `L45`: para cada row de pedido, chama `buildFullOrder`

#### Retorno da listagem

- `L47-L53`: retorna estrutura paginada:
  - `content`, `page`, `size`, `totalElements`, `totalPages`

### `findByUuid(uuid)`

- `L57-L63`: busca pedido por UUID.
- `L65`: se nao encontrou, retorna `null`.
- `L66`: se encontrou, transforma payload via `buildFullOrder`.

### `buildFullOrder(row)`

Monta o JSON final do contrato.

- `L70-L77`: carrega dados relacionados em paralelo:
  - customer, seller, items, shipment, payment, metadata
- `L79-L96`: transforma itens:
  - converte preco para `Number`
  - calcula `item.total = unit_price * quantity`
  - mapeia categoria/subcategoria
- `L98`: soma total do pedido (`reduce`)
- `L100-L131`: monta objeto final no contrato esperado:
  - status em lowercase
  - blocos aninhados (`customer`, `seller`, `items`, etc.)
  - campos snake_case no payload (`created_at`, `tracking_code`, ...)

### Helpers

- `fetchOne(table, id)`:
  - retorna `null` se sem id
  - faz `SELECT * FROM <table> WHERE id = $1`
- `fetchItems(orderId)`:
  - join em `order_items`, `categories`, `sub_categories`
  - retorna array ja com categoria/subcategoria embutidas

---

## 6.7 Middleware de erro e async

## `asyncHandler.js`

- recebe uma funcao async (`fn`)
- devolve middleware que executa `Promise.resolve(fn(...)).catch(next)`
- qualquer throw/rejection vai para `errorHandler`

## `errorHandler.js`

- se a resposta ja foi enviada, delega (`next(err)`)
- loga erro no server
- responde padrao `500 {"error":"Internal server error"}`

---

## 7) SQL usado pela API (resumo)

Principais consultas:

1. Count para paginacao:
   - `SELECT COUNT(*) FROM orders o ...`
2. Lista de pedidos paginados:
   - `SELECT ... FROM orders o ... ORDER BY created_at ... LIMIT ... OFFSET ...`
3. Detalhe por UUID:
   - `SELECT ... FROM orders o WHERE o.uuid = $1`
4. Entidades relacionadas:
   - `SELECT * FROM customers/sellers/shipments/payments/order_metadata WHERE id = $1`
5. Itens e categoria:
   - `SELECT oi.*, c.name, sc.id... FROM order_items oi LEFT JOIN categories ...`

Todos os valores dinamicos usam parametros (`$1`, `$2`, ...), evitando SQL injection nos filtros.

---

## 8) Tratativas de erro e retornos HTTP

Comportamento atual:

- sucesso listagem: `200` + pagina
- sucesso detalhe: `200` + pedido
- pedido inexistente por UUID: `404`
- qualquer erro interno (DB indisponivel, exception de codigo): `500`

Observacao importante:

- Hoje nao ha tratamento especifico para erro de banco (ex.: auth fail). Tudo cai em `500`.
- Em prova/pergunta, voce pode sugerir evolucao para retornar `503` quando DB estiver fora.

---

## 9) Paginacao e ordenacao (logica exata)

- `page` default `0`, minimo `0`.
- `size` default `20`, minimo `1`, maximo `100`.
- `offset = page * size`.
- `totalPages = Math.ceil(totalElements / size)`.
- `sort`: apenas `"asc"` mantem ascendente; qualquer outro valor vira descendente (`desc`).

---

## 10) Mapeamento do payload (campos)

Cada pedido retornado tem:

- `uuid`
- `created_at`
- `channel`
- `total` (calculado)
- `status`
- `customer`
- `seller`
- `items` (cada item com `total` calculado)
- `shipment`
- `payment`
- `metadata`

Isso atende o contrato da atividade (totais dinamicos e dados aninhados).

---

## 11) Como executar e validar rapidamente

No diretório `api/`:

```bash
npm install
npm run dev
```

Smoke tests:

```bash
GET http://localhost:3000/orders
GET http://localhost:3000/orders?status=paid&page=0&size=10&sort=desc
GET http://localhost:3000/orders?codigoCliente=7788
GET http://localhost:3000/orders?productId=9001
GET http://localhost:3000/orders/ORD-2025-0001
```

---

## 12) Perguntas provaveis do professor (com resposta curta)

- **Onde a API consulta o banco?**  
  Em `src/repositories/orderRepository.js`, via `pool.query(...)`.

- **Onde sao tratados filtros e paginacao?**  
  Parse no service (`orderService.js`) e SQL dinamico no repository.

- **Como evita SQL injection?**  
  Parametrizacao (`$1`, `$2`, ...) em todas entradas de usuario.

- **Como calcula os totais?**  
  `item.total = unit_price * quantity` e `order.total = soma dos itens` em `buildFullOrder`.

- **Como trata erro?**  
  `asyncHandler` captura excecoes async e `errorHandler` responde 500.

- **Como retorna 404?**  
  No controller `getByUuid`, quando service retorna `null`.

---

## 13) Pontos de melhoria (se ele perguntar evolucao)

1. Adicionar validacao de schema (`zod`/`joi`) para query params.
2. Diferenciar erro de infraestrutura (`503`) de erro interno (`500`).
3. Incluir testes automatizados (Jest + Supertest).
4. Otimizar N+1 queries com joins agregados para listagem.
5. Adicionar endpoint `/health`.

---

## 14) Conclusao

A API esta organizada em camadas, cumpre os requisitos funcionais da atividade, consome o PostgreSQL corretamente, aplica filtros/paginacao/ordenacao, calcula totais dinamicamente e entrega payload no formato esperado pelo front.

Se voce dominar os arquivos `orderService.js` e `orderRepository.js`, voce responde praticamente qualquer pergunta tecnica da banca.

