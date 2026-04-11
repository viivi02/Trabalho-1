package com.pubsub6.grupo.pubsub;

import com.google.cloud.pubsub.v1.MessageReceiver;
import com.pubsub6.grupo.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class PubSubSubscriber {

    private final OrderService orderService;

    public MessageReceiver receiver() {
        return (message, consumer) -> {
            String json = message.getData().toStringUtf8();
            try {
                orderService.processOrder(json);
                consumer.ack();
            } catch (Exception e) {
                log.error("Falha ao processar mensagem [id={}]: {}", message.getMessageId(), e.getMessage());
                consumer.nack();
            }
        };
    }
}
