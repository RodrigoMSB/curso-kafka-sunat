package com.novatech.kafka;

import org.apache.kafka.common.serialization.Deserializer;
import tools.jackson.databind.json.JsonMapper;

/**
 * Deserializer propio: convierte bytes JSON de vuelta en un Pedido.
 * El contrato (estructura del JSON) debe coincidir con el del serializer.
 */
public class PedidoDeserializer implements Deserializer<Pedido> {

    private final JsonMapper mapper = JsonMapper.builder().build();

    @Override
    public Pedido deserialize(String topic, byte[] data) {
        if (data == null) {
            return null;
        }
        try {
            return mapper.readValue(data, Pedido.class);
        } catch (Exception e) {
            throw new RuntimeException("Error deserializando Pedido", e);
        }
    }
}
