# Trabalho-1
Trabalho 1º bimestre computação em nuvem II

## 📊 Banco de Dados

### 🧩 Diagrama Entidade-Relacionamento (DER)

![DER](./database/dernuvemII.drawio.png)

---

### 🧠 Modelagem

O modelo foi estruturado de forma normalizada, separando entidades como **cliente**, **pedido**, **produto** e **item_pedido**.

A tabela **pedido** armazena as informações principais da compra, enquanto **item_pedido** representa a relação entre pedidos e produtos, permitindo múltiplos itens por pedido.

Entidades complementares como **payment**, **shipment** e **metadata** foram modeladas separadamente para manter organização, flexibilidade e aderência ao payload da aplicação.

O campo **indexed_at** registra o momento em que o dado foi persistido no banco, atendendo ao requisito de rastreabilidade da ingestão.

Os valores totais dos pedidos e itens não são armazenados no banco, sendo calculados dinamicamente pela API conforme regra de negócio.

---

### 📘 Dicionário de Dados

| Tabela      | Campo      | Tipo      | Descrição                       |
| ----------- | ---------- | --------- | ------------------------------- |
| pedido      | uuid       | VARCHAR   | Identificador único do pedido   |
| pedido      | status     | VARCHAR   | Status do pedido                |
| pedido      | indexed_at | TIMESTAMP | Data de ingestão no banco       |
| item_pedido | quantity   | INT       | Quantidade do produto no pedido |
| item_pedido | unit_price | DECIMAL   | Preço unitário do produto       |

---

### ⚙️ Como rodar o banco de dados
#### 1. Criar o banco
CREATE DATABASE marketplace;
#### 2. Selecionar o banco
USE marketplace;
#### 3. Executar o schema (criação das tabelas)
SOURCE database/schema.sql;
#### 4. Executar os índices
SOURCE database/indexes.sql;