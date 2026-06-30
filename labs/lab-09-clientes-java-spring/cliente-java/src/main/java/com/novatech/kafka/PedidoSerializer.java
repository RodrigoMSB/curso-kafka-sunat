package com.novatech.kafka;

import org.apache.kafka.common.serialization.Serializer;
import tools.jackson.databind.json.JsonMapper;

/**
 * Serializer propio: convierte un Pedido en bytes JSON.
 * Demuestra que un serializer es, en esencia, "objeto -> byte[]".
 */
public class PedidoSerializer implements Serializer<Pedido> {

    private final JsonMapper mapper = JsonMapper.builder().build();

    @Override
    public byte[] serialize(String topic, Pedido data) {
        if (data == null) {
            return null;
        }
        try {
            return mapper.writeValueAsBytes(data);
        } catch (Exception e) {
            throw new RuntimeException("Error serializando Pedido", e);
        }
    }
}
