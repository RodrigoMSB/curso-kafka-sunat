package com.novatech.kafka;

/**
 * Modelo de dominio que viaja por Kafka como JSON.
 */
public record Pedido(String pedidoId, String cliente, String producto, int cantidad, double monto) {
}
