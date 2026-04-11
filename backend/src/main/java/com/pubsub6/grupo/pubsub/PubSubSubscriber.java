package com.pubsub6.grupo.pubsub;

import com.google.cloud.pubsub.v1.MessageReceiver;
import com.pubsub6.grupo.service.OrderService;
import org.springframework.stereotype.Component;

@Component
public class PubSubSubscriber {

    private final OrderService service;

    public PubSubSubscriber(OrderService service) {
        this.service = service;
    }

    public MessageReceiver receiver() {
        return (message, consumer) -> {

            try {
                String json = message.getData().toStringUtf8();
                System.out.println(json);
                service.processOrder(json);
                consumer.ack();
            } catch (Exception e) {
                consumer.nack();
            }
        };
    }
}
