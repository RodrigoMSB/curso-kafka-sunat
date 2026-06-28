# Parte 5: Desafío - Particionado y throughput

## Objetivo

Explorar cómo el particionado por clave afecta el throughput, y diseñar un experimento para encontrar el "sweet spot" para NovaTech.

---

## Reto 1: Sin clave vs con clave (mismo throughput)

Sin clave (round-robin / sticky):
```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 \
    --batch-size 65536 --linger-ms 10
```

Con clave (forzar partición específica): no es posible directamente con `kafka-producer-perf-test`, pero puedes producir manualmente:

```bash
seq 1 50000 | awk '{ print "K:msg_"$1 }' | \
    docker exec -i kafka-broker-1 kafka-console-producer \
        --bootstrap-server kafka-broker-1:29092 \
        --topic novatech.tuning.bench \
        --property "parse.key=true" \
        --property "key.separator=:" \
        --producer-property "batch.size=65536" \
        --producer-property "linger.ms=10"
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 50K cayeron en la MISMA partición? (verifica con describe-topic) | |
| ¿El throughput fue mejor o peor? | |
| ¿Por qué? | |

> **Pista**: una sola partición = un solo broker líder = sin paralelismo. Throughput limitado.

---

## Reto 2: Cambiar el particionador

Por defecto, Kafka 3.x+ usa `DefaultPartitioner` que distribuye uniformemente con `sticky batching`. Hay otros particionadores:
- `RoundRobinPartitioner`: estricto round-robin
- `UniformStickyPartitioner`: variante sticky

Prueba el round-robin estricto:

```bash
docker exec kafka-broker-1 kafka-producer-perf-test \
    --topic novatech.tuning.bench \
    --num-records 50000 \
    --record-size 200 \
    --throughput -1 \
    --producer-props \
        bootstrap.servers=kafka-broker-1:29092 \
        acks=all \
        partitioner.class=org.apache.kafka.clients.producer.RoundRobinPartitioner
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Throughput con RoundRobinPartitioner | |
| Comparado con default | |
| ¿Cuál es mejor? ¿Por qué? | |

---

## Reto 3: Reflexión final

| Pregunta | Tu respuesta |
|----------|-------------|
| Si tienes 6 vehículos VIP que generan el 80% del tráfico, ¿qué pasa con keys NVT-VIP-* y particionado por clave? | |
| ¿Cómo evitarías el "hot partitioning"? | |
| ¿En qué caso NO querrías garantizar orden por clave (y por tanto podrías ignorar el particionado por clave)? | |

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md` en la sección del desafío.
