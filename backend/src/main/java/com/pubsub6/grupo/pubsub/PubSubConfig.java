package com.pubsub6.grupo.pubsub;

import com.google.api.core.ApiService;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.cloud.pubsub.v1.Subscriber;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.pubsub.v1.ProjectSubscriptionName;
import com.pubsub6.grupo.config.PubSubProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Slf4j
@Configuration
@RequiredArgsConstructor
public class PubSubConfig {

    private final PubSubProperties props;

    @Bean(initMethod = "startAsync", destroyMethod = "stopAsync")
    public Subscriber subscriber(PubSubSubscriber handler) throws IOException {
        log.info("Conectando ao Pub/Sub: {}/{}", props.projectId(), props.subscriptionId());

        var credentials = ServiceAccountCredentials.fromStream(
                new FileInputStream(props.credentialsPath()));

        var subscriptionName = ProjectSubscriptionName.of(
                props.projectId(), props.subscriptionId());

        Subscriber sub = Subscriber.newBuilder(subscriptionName, handler.receiver())
                .setCredentialsProvider(() -> credentials)
                .build();

        sub.addListener(new ApiService.Listener() {
            @Override
            public void failed(ApiService.State from, Throwable failure) {
                log.error("Subscriber falhou [state={}]: {}", from, failure.getMessage(), failure);
            }

            @Override
            public void running() {
                log.info("Subscriber conectado e aguardando mensagens");
            }
        }, MoreExecutors.directExecutor());

        return sub;
    }
}
