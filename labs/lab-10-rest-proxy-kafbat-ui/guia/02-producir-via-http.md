# Parte 2: Producir vía HTTP

## Objetivo

Enviar mensajes a un tópico Kafka usando solo HTTP, sin ningún cliente nativo.

## Contexto

Producir por REST es **sin estado**: un POST con el mensaje, y listo. El REST Proxy lo escribe en Kafka y te devuelve en qué partición y offset quedó.

---

## Actividad 1: Producir un mensaje

```bash
rest-cli/rest-produce.sh novatech.lab10.pedidos '{"pedido":1001,"cliente":"Courier-X","monto":2300}'
```

O directo con curl:

```bash
curl -s -X POST \
  -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data '{"records":[{"value":{"pedido":1001,"cliente":"Courier-X","monto":2300}}]}' \
  http://localhost:8082/topics/novatech.lab10.pedidos
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué `partition` y `offset` devolvió la respuesta? | |
| ¿Por qué el `Content-Type` es `application/vnd.kafka.json.v2+json`? | |

---

## Actividad 2: Producir varios mensajes

Un POST puede llevar varios registros a la vez:

```bash
curl -s -X POST \
  -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data '{"records":[{"value":{"pedido":1002}},{"value":{"pedido":1003}},{"value":{"pedido":1004}}]}' \
  http://localhost:8082/topics/novatech.lab10.pedidos
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas entradas `offsets` devolvió? | |
| ¿Cayeron todos en la misma partición o se repartieron? | |

---

## Siguiente paso

Continúa con [Parte 3: Consumir vía HTTP](03-consumir-via-http.md).
