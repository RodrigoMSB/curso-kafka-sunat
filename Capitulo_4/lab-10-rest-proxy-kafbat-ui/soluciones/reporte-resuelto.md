# Lab 10 — Reporte resuelto (solución de referencia)

## Parte 1
- Sí, `novatech.lab10.pedidos` aparece en `GET /topics`. La respuesta viene en **JSON**.
- El endpoint reporta **3** particiones (RF 3).
- Ventaja: cualquier cliente que hable HTTP puede consultar sin integrar una librería Kafka ni manejar el protocolo binario.

## Parte 2
- La respuesta trae un array `offsets` con `partition` y `offset` por registro (los valores exactos dependen de la corrida).
- El `Content-Type` `application/vnd.kafka.json.v2+json` le dice al REST Proxy **cómo interpretar el cuerpo** (formato JSON, API v2). Sin él, rechaza la petición.
- Al producir 3 registros devuelve **3** entradas en `offsets`. Pueden caer en distintas particiones (sin key, el reparto es por round-robin/sticky).

## Parte 3
- Primer poll: típicamente **vacío** (inicializa la asignación de particiones). Segundo poll: trae los mensajes.
- El primer poll viene vacío porque la suscripción/asignación recién se está estableciendo cuando se pide.
- Producir es sin estado (un POST independiente). Consumir necesita recordar el offset por dónde va cada grupo → el REST Proxy mantiene una **instancia de consumer** con estado en el servidor.
- Si no borras la instancia, queda ocupando recursos en el REST Proxy y reteniendo su parte del grupo hasta que expire por timeout.

## Parte 4
- Sí, los pedidos HTTP se ven en Kafbat como mensajes normales.
- Kafbat **no** distingue el origen: para Kafka, un mensaje es un mensaje. El cliente nativo (`kafka-console-consumer`) **sí** ve el mensaje que entró por HTTP.
- Esto demuestra que el mensaje vive en **Kafka**, no en el REST Proxy: el proxy es solo una puerta de entrada/salida.

## Desafío
Ejemplo de secuencia válida: `GET /topics` → `POST /topics/<t>` (×2) → `POST /consumers/<g>` → `POST .../subscription` → `GET .../records` → `DELETE .../instances/<i>`.

---

*Solución - Lab 10*
