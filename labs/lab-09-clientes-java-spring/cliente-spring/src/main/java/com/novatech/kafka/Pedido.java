package com.novatech.kafka;

public record Pedido(String pedidoId, String cliente, String producto, int cantidad, double monto) {
}
