# Lab 09 — Reporte resuelto (solución de referencia)

> Las particiones/offsets exactos dependen de la corrida; aquí van los conceptos y resultados esperados.

## Parte 1
- Sin key fija que agrupe, los 20 pedidos se reparten entre las 3 particiones (cada pedido usa su `pedidoId` como key → distribución por hash). El orden se respeta **dentro de cada partición**, no globalmente.
- Propiedades mínimas del productor: `bootstrap.servers`, `key.serializer`, `value.serializer`, y en este caso `acks`.
- `acks=all`: el productor espera confirmación de **todas** las réplicas in-sync antes de dar el envío por exitoso (máxima durabilidad).

## Parte 2
- Kafka solo almacena y transporta `byte[]`; no conoce tipos Java. La conversión objeto↔bytes es responsabilidad del cliente (serializer/deserializer).
- En Kafbat el valor se ve como JSON legible (ventaja para depurar frente a un binario opaco).
- Es un "contrato" porque productor y consumidor deben acordar la estructura: si uno cambia el formato sin el otro, la deserialización falla o produce datos incorrectos.

## Parte 3
- Sí, el `@KafkaListener` registra el pedido recibido tras el POST.
- `ProductorService` usa `KafkaTemplate` para enviar (encapsula el `KafkaProducer`, la fábrica y los serializers).
- Los serializers se configuran en `KafkaConfig` (`@Bean` de `ProducerFactory`/`ConsumerFactory`), no en cada llamada.
- Spring ahorra el boilerplate de crear productor/consumidor, el bucle de `poll`, y el manejo del ciclo de vida; a cambio, hay "magia" y configuración menos explícita que en la API nativa.

## Parte 4
- Con 3 particiones y 3 instancias del mismo grupo, cada instancia atiende **una** partición; los 30 pedidos se reparten ~10 por instancia.
- Al matar una instancia, sus particiones se **reasignan** (rebalanceo) a las que quedan.
- Una 4ª instancia con solo 3 particiones quedaría **inactiva** (idle): no hay partición libre para asignarle. El paralelismo máximo de consumo = número de particiones.

## Desafío
- Sí: `cliente-spring` consume los pedidos producidos por `cliente-java`. El mensaje en el tópico es JSON estándar; cualquier consumidor que sepa deserializar ese JSON lo lee, sin importar con qué cliente se produjo.

---

*Solución - Lab 09*
