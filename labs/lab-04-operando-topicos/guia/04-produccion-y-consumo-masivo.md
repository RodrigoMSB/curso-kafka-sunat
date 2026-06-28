# Parte 4: Producción y consumo masivo

## Objetivo

Producir miles de mensajes, consumirlos de distintas formas (desde el inicio, desde un offset específico, de una partición concreta), y medir el throughput real del broker.

## Contexto

Los Labs anteriores manejaron mensajes de a uno. En producción, los productores envían **miles por segundo**. Vamos a generar carga real y observar qué hace el clúster.

---

## Actividad 1: Producción masiva con clave

Llena el tópico GPS con 5.000 mensajes, distribuidos por vehículos:

```bash
kafka-cli/produce-bulk.sh novatech.gps.realtime 5000 --key-pattern NVT
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos segundos tomó? | |
| ¿Cuál fue la tasa aproximada (msg/seg)? | |

Verifica el tópico:

```bash
kafka-cli/describe-topic.sh novatech.gps.realtime | head -25
```

Y en Kafbat UI > Topics > `novatech.gps.realtime` > Overview, observa el gráfico de throughput.

---

## Actividad 2: Consumo desde el principio

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.gps.realtime \
    --from-beginning \
    --max-messages 20 \
    --property "print.key=true" \
    --property "key.separator= -> " \
    --timeout-ms 10000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los mensajes vienen ordenados por clave? | |
| ¿Vienen ordenados globalmente por orden de producción? | |
| ¿Qué claves (NVT-N) ves? | |

---

## Actividad 3: Consumo de UNA partición específica

Lee solo de la partición 3:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.gps.realtime \
    --partition 3 \
    --offset earliest \
    --max-messages 10 \
    --property "print.key=true" \
    --property "key.separator= -> " \
    --timeout-ms 10000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Todos los mensajes de la partición 3 tienen claves "consistentes"? (mismas o pocas claves) | |
| ¿Por qué la partición 3 no tiene TODAS las claves? | |

---

## Actividad 4: Consumir desde un offset específico

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.gps.realtime \
    --partition 0 \
    --offset 100 \
    --max-messages 5 \
    --timeout-ms 10000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Empezó desde el mensaje 101 (offsets son 0-indexed)? | |
| ¿Por qué te puede interesar leer desde un offset específico en producción? | |

---

## Actividad 5: Test de throughput real

Ejecuta el productor de performance oficial de Kafka:

```bash
kafka-cli/perf-test.sh novatech.audit.events 10000 200
```

Esto produce 10.000 mensajes de 200 bytes cada uno y mide:
- Throughput (msg/seg, MB/seg)
- Latencia promedio, p50, p95, p99

| Pregunta | Tu respuesta |
|----------|-------------|
| Throughput observado (msg/seg) | |
| Throughput observado (MB/seg) | |
| Latencia p99 (ms) | |
| ¿Es consistente con lo esperado para Kafka local? | |

> **Referencia**: en un Mac M1/M2 con Docker Desktop, deberías ver entre 5.000 y 50.000 msg/seg para mensajes de 200B con `acks=all`. Si ves menos de 1.000, hay algo raro.

---

## Actividad 6: Comparar con `acks=1`

Modifica el comando para que el productor solo espere ACK del líder (no de los followers):

```bash
docker exec kafka-broker-1 kafka-producer-perf-test \
    --topic novatech.audit.events \
    --num-records 10000 \
    --record-size 200 \
    --throughput -1 \
    --producer-props bootstrap.servers=kafka-broker-1:29092 acks=1
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Throughput con `acks=1` | |
| Throughput con `acks=all` (de Actividad 5) | |
| ¿Cuánto más rápido es `acks=1`? | |
| ¿Qué se pierde con `acks=1`? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Producción masiva | Generaste 5K y 10K mensajes |
| Consumir partición específica | Leíste la partición 3 sin las demás |
| Consumir desde offset | Leíste desde offset=100 |
| Throughput real | Mediste msg/seg y latencia con perf-test |
| `acks=all` vs `acks=1` | Comparaste el costo de durabilidad |

---

## Siguiente paso

Continúa con [Parte 5: Desafío RF y eliminación](05-desafio-rf-y-eliminacion.md) (opcional).
