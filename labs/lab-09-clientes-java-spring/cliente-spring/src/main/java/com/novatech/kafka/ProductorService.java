package com.novatech.kafka;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class ProductorService {

    private static final String TOPIC = "novatech.lab09.pedidos";
    private final KafkaTemplate<String, Pedido> kafkaTemplate;

    public ProductorService(KafkaTemplate<String, Pedido> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void enviar(Pedido pedido) {
        kafkaTemplate.send(TOPIC, pedido.pedidoId(), pedido);
    }
}
