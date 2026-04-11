package com.pubsub6.grupo.pubsub;

import com.google.api.core.ApiService;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.cloud.pubsub.v1.Subscriber;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.pubsub.v1.ProjectSubscriptionName;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Configuration
public class PubSubConfig {

    private static final Logger log = LoggerFactory.getLogger(PubSubConfig.class);

    @Value("${app.pubsub.project-id}")
    private String projectId;

    @Value("${app.pubsub.subscription-id}")
    private String subscriptionId;

    @Value("${app.pubsub.credentials-path}")
    private String credentialsPath;

    @Bean(initMethod = "startAsync", destroyMethod = "stopAsync")
    public Subscriber subscriber(PubSubSubscriber subscriber) throws IOException {

        log.info("Criando subscriber para {}/{} com credenciais de {}", projectId, subscriptionId, credentialsPath);

        ServiceAccountCredentials credentials =
                ServiceAccountCredentials.fromStream(new FileInputStream(credentialsPath));

        ProjectSubscriptionName subscriptionName =
                ProjectSubscriptionName.of(projectId, subscriptionId);

        Subscriber sub = Subscriber.newBuilder(subscriptionName, subscriber.receiver())
                .setCredentialsProvider(() -> credentials)
                .build();

        sub.addListener(new ApiService.Listener() {
            @Override
            public void failed(ApiService.State from, Throwable failure) {
                log.error("Subscriber FALHOU (state={}): {}", from, failure.getMessage(), failure);
            }

            @Override
            public void running() {
                log.info("Subscriber CONECTADO e recebendo mensagens");
            }
        }, MoreExecutors.directExecutor());

        return sub;
    }
}
