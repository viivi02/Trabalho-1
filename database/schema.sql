CREATE TABLE cliente (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    document VARCHAR(20)
);

CREATE TABLE seller (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(2)
);

CREATE TABLE categoria (
    id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE subcategoria (
    id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    categoria_id VARCHAR(10),
    FOREIGN KEY (categoria_id) REFERENCES categoria(id)
);

CREATE TABLE produto (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    category_id VARCHAR(10),
    subcategory_id VARCHAR(10),
    FOREIGN KEY (category_id) REFERENCES categoria(id),
    FOREIGN KEY (subcategory_id) REFERENCES subcategoria(id)
);

CREATE TABLE pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(50) UNIQUE,
    cliente_id INT,
    seller_id INT,
    status VARCHAR(20),
    channel VARCHAR(50),
    created_at TIMESTAMP,
    indexed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES cliente(id),
    FOREIGN KEY (seller_id) REFERENCES seller(id)
);

CREATE TABLE item_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT,
    produto_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    FOREIGN KEY (pedido_id) REFERENCES pedido(id),
    FOREIGN KEY (produto_id) REFERENCES produto(id)
);

CREATE TABLE payment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT UNIQUE,
    method VARCHAR(50),
    status VARCHAR(20),
    transaction_id VARCHAR(100),
    FOREIGN KEY (pedido_id) REFERENCES pedido(id)
);

CREATE TABLE shipment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT UNIQUE,
    carrier VARCHAR(50),
    service VARCHAR(50),
    status VARCHAR(20),
    tracking_code VARCHAR(100),
    FOREIGN KEY (pedido_id) REFERENCES pedido(id)
);

CREATE TABLE metadata (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT UNIQUE,
    source VARCHAR(50),
    user_agent VARCHAR(255),
    ip_address VARCHAR(50),
    FOREIGN KEY (pedido_id) REFERENCES pedido(id)
);

