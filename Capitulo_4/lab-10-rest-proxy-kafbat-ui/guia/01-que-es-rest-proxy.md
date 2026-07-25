# Parte 1: Qué es REST Proxy

## Objetivo

Entender qué resuelve Confluent REST Proxy y verificar que está exponiendo el clúster por HTTP.

## Contexto

Kafka habla su propio protocolo binario sobre TCP. Para usarlo necesitas una librería cliente. REST Proxy se pone **en el medio**: traduce HTTP ↔ protocolo Kafka, para que cualquier sistema que sepa hacer un `curl` pueda producir y consumir.

| Usa REST Proxy cuando... | Usa un cliente nativo cuando... |
|--------------------------|----------------------------------|
| El lenguaje no tiene buen cliente Kafka | Necesitas máximo throughput |
| Es un sistema legacy o un script rápido | Necesitas baja latencia |
| El cliente está detrás de un firewall que solo deja HTTP | Tienes control del stack del cliente |

---

## Actividad 1: Verificar que el REST Proxy responde

Lista los tópicos del clúster, pero **por HTTP** (no con `kafka-topics`):

```bash
rest-cli/rest-list-topics.sh
```

O directo con curl:

```bash
curl -s http://localhost:8082/topics
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece `novatech.lab10.pedidos` en la respuesta? | |
| ¿En qué formato viene la respuesta? | |

---

## Actividad 2: Inspeccionar un tópico por HTTP

```bash
curl -s http://localhost:8082/topics/novatech.lab10.pedidos
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones reporta el endpoint? | |
| ¿Qué ventaja tiene poder consultar esto por HTTP en vez de con un cliente Kafka? | |

---

## Siguiente paso

Continúa con [Parte 2: Producir vía HTTP](02-producir-via-http.md).
