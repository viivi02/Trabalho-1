package com.pubsub6.grupo.exception;

public class OrderNotFoundException extends RuntimeException {

    public OrderNotFoundException(String uuid) {
        super("Pedido não encontrado: " + uuid);
    }
}
