CREATE INDEX idx_pedido_uuid ON pedido(uuid);
CREATE INDEX idx_pedido_cliente ON pedido(cliente_id);
CREATE INDEX idx_pedido_status ON pedido(status);
CREATE INDEX idx_item_produto ON item_pedido(produto_id);