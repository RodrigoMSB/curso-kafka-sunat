package com.novatech.kafka;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;

import java.time.Duration;
import java.util.List;
import java.util.Properties;

/**
 * Consumidor con la API nativa de kafka-clients.
 * Uso: mvn exec:java -Dexec.mainClass="com.novatech.kafka.ConsumidorApp" -Dexec.args="grupo-java-nativo"
 */
public class ConsumidorApp {

    private static final String TOPIC = "novatech.lab09.pedidos";
    private static final String BOOTSTRAP = "localhost:9092,localhost:9093,localhost:9094";

    public static void main(String[] args) {
        String grupo = args.length > 0 ? args[0] : "grupo-java-nativo";

        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, grupo);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, PedidoDeserializer.class.getName());
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        try (KafkaConsumer<String, Pedido> consumer = new KafkaConsumer<>(props)) {
            consumer.subscribe(List.of(TOPIC));
            System.out.println("Consumidor en grupo '" + grupo + "' escuchando " + TOPIC + " (Ctrl+C para salir)...");
            while (true) {
                ConsumerRecords<String, Pedido> records = consumer.poll(Duration.ofMillis(500));
                for (ConsumerRecord<String, Pedido> record : records) {
                    Pedido p = record.value();
                    System.out.printf("[particion %d offset %d] %s -> %s x%d ($%.2f)%n",
                            record.partition(), record.offset(),
                            p.cliente(), p.producto(), p.cantidad(), p.monto());
                }
            }
        }
    }
}
