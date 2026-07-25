package com.novatech.kafka;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

import java.util.Properties;
import java.util.UUID;

/**
 * Productor con la API nativa de kafka-clients.
 * Uso: mvn exec:java -Dexec.mainClass="com.novatech.kafka.ProductorApp" -Dexec.args="20"
 */
public class ProductorApp {

    private static final String TOPIC = "novatech.lab09.pedidos";
    private static final String BOOTSTRAP = "localhost:9092,localhost:9093,localhost:9094";

    public static void main(String[] args) {
        int total = args.length > 0 ? Integer.parseInt(args[0]) : 10;

        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, PedidoSerializer.class.getName());
        props.put(ProducerConfig.ACKS_CONFIG, "all");

        try (Producer<String, Pedido> producer = new KafkaProducer<>(props)) {
            for (int i = 1; i <= total; i++) {
                Pedido pedido = new Pedido(
                        UUID.randomUUID().toString(),
                        "cliente-" + i,
                        "producto-" + (i % 5),
                        i,
                        i * 100.0);
                ProducerRecord<String, Pedido> record =
                        new ProducerRecord<>(TOPIC, pedido.pedidoId(), pedido);
                producer.send(record, (metadata, exception) -> {
                    if (exception != null) {
                        System.err.println("Error: " + exception.getMessage());
                    } else {
                        System.out.printf("Enviado a %s [particion %d, offset %d]%n",
                                metadata.topic(), metadata.partition(), metadata.offset());
                    }
                });
            }
            producer.flush();
            System.out.println("Total de pedidos enviados: " + total);
        }
    }
}
