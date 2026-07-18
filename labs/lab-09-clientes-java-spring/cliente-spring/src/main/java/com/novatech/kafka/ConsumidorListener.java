package com.novatech.kafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class ConsumidorListener {

    private static final Logger log = LoggerFactory.getLogger(ConsumidorListener.class);

    @KafkaListener(topics = "novatech.lab09.pedidos", groupId = "grupo-spring")
    public void escuchar(Pedido pedido) {
        log.info("Pedido recibido: {} -> {} x{} (${})",
                pedido.cliente(), pedido.producto(), pedido.cantidad(), pedido.monto());
    }
}
