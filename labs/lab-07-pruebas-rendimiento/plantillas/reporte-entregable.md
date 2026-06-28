# Reporte del Lab 06: Productores afilados al milímetro

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Tuning de batch.size y linger.ms

### Baseline

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| Latencia media (ms) | |
| Latencia p99 (ms) | |

### Batch + linger

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| % mejora vs baseline | |

### Compresión LZ4

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| % mejora vs baseline | |

### Combinación pro

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| % mejora vs baseline | |

### Máximos extremos

| Métrica | Valor |
|---------|-------|
| records/sec | |
| Latencia p99 (ms) | |
| ¿Subió throughput o latencia? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué config dio mejor throughput? | |
| ¿Qué config dio peor latencia? | |
| ¿Hay trade-off entre throughput y latencia? | |
| Para NovaTech (eventos GPS), ¿qué priorizarías? | |
| Para pagos en tiempo real, ¿qué priorizarías? | |

---

## Parte 2: Niveles de acks

| Acks | Throughput (msg/seg) | Latencia p99 (ms) | Pérdida posible |
|------|----------------------|-------------------|-----------------|
| 0    | | | |
| 1    | | | |
| all  | | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuánto más rápido es acks=0 vs acks=all? | |
| ¿Cuál es el costo de acks=all? | |
| ¿Cuándo usarías acks=0? | |
| ¿Cuándo acks=1? | |
| ¿Cuándo acks=all? | |

---

## Parte 3: Idempotencia y duplicados

| Métrica | Naive | Idempotente |
|---------|-------|-------------|
| Mensajes producidos | 100 | 100 |
| Total en el tópico | | |
| ¿Hay duplicados? | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| Error con `enable.idempotence=true` y `acks=1` | |
| ¿Por qué exige acks=all? | |
| ¿Qué garantiza la idempotencia? | |
| ¿Qué NO garantiza? | |
| ¿Idempotente + 1 partición = exactly-once? | |
| ¿Idempotente + N particiones = exactly-once? | |

---

## Parte 4: Transacciones exactly-once

| Pregunta | Tu respuesta |
|----------|-------------|
| Mensajes vistos con read_committed (commit) | |
| Mensajes vistos con read_uncommitted (commit) | |
| Mensajes vistos con read_committed (post abort) | |
| Mensajes vistos con read_uncommitted (post abort) | |
| ¿Cuántas transacciones lista `kafka-transactions list`? | |
| Estado de las transacciones | |

---

## Parte 5: Desafío - Particionado y throughput

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 50K con clave fija cayeron en la misma partición? | |
| Throughput con clave fija | |
| Throughput sin clave | |
| Throughput con RoundRobinPartitioner | |
| ¿Cuál es mejor? ¿Por qué? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| 6 VIPs con 80% del tráfico y particionado por clave: ¿qué pasa? | |
| ¿Cómo evitarías el hot partitioning? | |
| ¿Cuándo NO importa el orden por clave? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre tuning de productores:

```


```

---

*Lab 06 - Curso de Administración de Apache Kafka con Confluent Platform*
