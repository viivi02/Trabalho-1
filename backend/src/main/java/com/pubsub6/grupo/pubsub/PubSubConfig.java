package com.pubsub6.grupo.pubsub;

import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.cloud.pubsub.v1.Subscriber;
import com.google.pubsub.v1.ProjectSubscriptionName;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Configuration
public class PubSubConfig {

    @Bean(initMethod = "startAsync", destroyMethod = "stopAsync")
    public Subscriber subscriber(PubSubSubscriber subscriber) throws IOException {

        String projectId = "serjava-demo";
        String subscriptionId = "sub-grupo6";

        ServiceAccountCredentials credentials =
                ServiceAccountCredentials.fromStream(
                        new FileInputStream("key-grupo6.json"));

        ProjectSubscriptionName subscriptionName =
                ProjectSubscriptionName.of(projectId, subscriptionId);

        return Subscriber.newBuilder(subscriptionName, subscriber.receiver())
                .setCredentialsProvider(() -> credentials)
                .build();
    }
}
