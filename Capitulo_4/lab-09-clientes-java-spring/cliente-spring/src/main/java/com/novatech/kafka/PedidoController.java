package com.novatech.kafka;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Dispara producción de pedidos vía HTTP:
 * POST http://localhost:8081/api/pedidos
 * Body JSON: {"pedidoId":"p1","cliente":"ACME","producto":"caja","cantidad":3,"monto":1500.0}
 */
@RestController
@RequestMapping("/api/pedidos")
public class PedidoController {

    private final ProductorService productorService;

    public PedidoController(ProductorService productorService) {
        this.productorService = productorService;
    }

    @PostMapping
    public ResponseEntity<String> crear(@RequestBody Pedido pedido) {
        productorService.enviar(pedido);
        return ResponseEntity.ok("Pedido enviado: " + pedido.pedidoId());
    }
}
