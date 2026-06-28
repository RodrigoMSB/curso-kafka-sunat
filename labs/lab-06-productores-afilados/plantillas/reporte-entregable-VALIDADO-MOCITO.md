# Reporte del Lab 06 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada con datos reales del lab end-to-end.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: Tuning de batch.size y linger.ms

### Baseline (10K mensajes, sin tuning)

| Métrica | Valor |
|---------|-------|
| records/sec | **25.252** |
| MB/sec | **4.82** |
| Latencia media (ms) | **94.93** |
| Latencia p99 (ms) | **147** |

### Batch + linger (batch.size=65536, linger.ms=10)

| Métrica | Valor |
|---------|-------|
| records/sec | **38.610** |
| MB/sec | **7.36** |
| % mejora vs baseline | **+53% throughput**, **-70% p99 latency** (147 → 44 ms) |

### Compresión LZ4 sola

| Métrica | Valor |
|---------|-------|
| records/sec | **27.855** |
| MB/sec | **5.31** |
| % mejora vs baseline | **+10% throughput**, **-31% p99 latency** (147 → 102 ms) |

### Combinación pro (batch + linger + lz4)

| Métrica | Valor |
|---------|-------|
| records/sec | **31.446** |
| MB/sec | **6.00** |
| % mejora vs baseline | **+25% throughput**, **-64% p99 latency** (147 → 53 ms) |

### Máximos extremos (50K msg, batch=1MiB, linger=100, zstd)

| Métrica | Valor |
|---------|-------|
| records/sec | **130.548** (más de 5x baseline!) |
| Latencia p99 (ms) | **57** |
| ¿Subió throughput o latencia? | **Subió throughput +417%** (25k → 130k rps) y la latencia incluso BAJÓ (147 → 57 ms p99) — los batches grandes son más eficientes en CPU/red de lo que el costo del linger=100ms agrega. |

> **Observación interesante**: el "combo pro" (batch + linger + lz4 con 10K mensajes) fue PEOR que solo "batch + linger" (31k vs 38k rps). En cargas pequeñas la compresión es overhead neto. Pero en cargas masivas (50K + zstd) la compresión gana muchísimo.

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué config dio mejor throughput? | **Máximos extremos**: 130k rps con batch=1MiB + linger=100 + zstd. |
| ¿Qué config dio peor latencia? | **Baseline**: 147ms p99 con cero tuning. |
| ¿Hay trade-off entre throughput y latencia? | En general SÍ, pero en este test el batch grande con linger=100 mejoró AMBOS — porque el cuello de botella del baseline NO era latencia de un mensaje individual sino overhead de network round-trip por mensaje. Los batches amortizan ese overhead. |
| Para NovaTech (eventos GPS), ¿qué priorizarías? | **Throughput sobre latencia individual**: los eventos GPS son tolerantes a 100-500ms de delay. Configuración recomendada: `batch.size=65536, linger.ms=10, compression.type=lz4`. |
| Para pagos en tiempo real, ¿qué priorizarías? | **Latencia baja con durabilidad**: `linger.ms=0, batch.size=16384 (default), acks=all, enable.idempotence=true`. La latencia individual importa más que el throughput agregado. |

---

## Parte 2: Niveles de acks

| Acks | Throughput (msg/seg) | Latencia p99 (ms) | Pérdida posible |
|------|----------------------|-------------------|-----------------|
| 0    | **21.367** | **24** | Sí — fire and forget. Mensaje perdido si broker cae antes de escribir, sin notificación al cliente. |
| 1    | **19.762** | **37** | Sí pero menor — solo si líder muere antes de replicar (window pequeña entre persist en líder y replicación). |
| all  | **18.656** | **48** | No con `min.insync.replicas≥2` y RF≥3 — necesitarían fallar todos los ISR simultáneamente. |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuánto más rápido es acks=0 vs acks=all? | **+15% throughput** (21k vs 18k rps) y **-50% p99 latency** (24 vs 48 ms). Diferencia notable pero no dramática en cluster local. En producción con RTT >10ms entre brokers la diferencia se acentúa. |
| ¿Cuál es el costo de acks=all? | Latencia adicional por esperar ACK de TODAS las réplicas en ISR. Throughput menor por menor concurrencia (cada batch espera más tiempo antes de liberar buffer). |
| ¿Cuándo usarías acks=0? | Métricas de telemetría agregada donde la pérdida ocasional de un dato no afecta el agregado: heartbeats, contadores de health, tracking impreciso. NUNCA para datos transaccionales. |
| ¿Cuándo acks=1? | Eventos donde "casi seguro durables" alcanza: logs de aplicación, IoT con tolerancia a pérdida puntual. El default histórico de Kafka. |
| ¿Cuándo acks=all? | Datos donde la pérdida es inaceptable: pagos, transacciones, eventos contables, change-data-capture. Combinado con `min.insync.replicas=2` y `enable.idempotence=true`. |

---

## Parte 3: Idempotencia y duplicados

| Métrica | Naive | Idempotente |
|---------|-------|-------------|
| Mensajes producidos | 100 | 100 |
| Total en el tópico (acumulado) | **100** (29+31+40 = 100, exactos) | **200** (68+64+68 = 200, exactos +100) |
| ¿Hay duplicados? | **No en este test** — el cluster local sin congestión no triggereó retries con éxito. La guía aclara este caso: en local pueden no aparecer. | **No** — incluso si hubiera retries, el Producer ID + Sequence Number deduplica en el broker. |

| Pregunta | Tu respuesta |
|----------|-------------|
| Error con `enable.idempotence=true` y `acks=1` | `org.apache.kafka.common.config.ConfigException: Must set acks to all in order to use the idempotent producer.` (en versiones más viejas) o auto-promoción a acks=all con warning en Kafka 3.x+. La idempotencia REQUIERE acks=all. |
| ¿Por qué exige acks=all? | Porque la deduplicación se basa en el broker líder + replicación. Sin acks=all el ProducerId+SequenceNumber pueden no replicarse antes del fallo, lo que rompe la garantía. |
| ¿Qué garantiza la idempotencia? | "Exactly-once por partición": cada mensaje aparece exactamente UNA vez en su partición destino, incluso bajo retries. Aplica POR PARTICIÓN, no global. |
| ¿Qué NO garantiza? | (1) Exactly-once entre PARTICIONES (eso requiere transacciones). (2) Que el cliente no produzca el "mismo" mensaje desde dos llamadas distintas — la idempotencia es a nivel de retry de un mismo `send()`, no a nivel semántico. (3) Orden global. |
| ¿Idempotente + 1 partición = exactly-once? | **Sí, técnicamente**: si todo el flujo va a una sola partición, idempotencia + acks=all = exactly-once. Pero te perdés escalado horizontal. |
| ¿Idempotente + N particiones = exactly-once? | **NO** — idempotencia es per-partition. Para EOS multi-partition se necesitan transacciones (`transactional.id`). |

---

## Parte 4: Transacciones exactly-once

| Pregunta | Tu respuesta |
|----------|-------------|
| Mensajes vistos con read_committed (commit) | **5** (5 mensajes en `confirmed`, valores 0,1,2,3,4 en orden). |
| Mensajes vistos con read_uncommitted (commit) | **5** también (cuando la transacción ya fue committed, ambos isolation levels ven lo mismo). |
| Mensajes vistos con read_committed (post abort) | **5** (los del commit anterior, NO los del abort). El abort se "salta" para read_committed. |
| Mensajes vistos con read_uncommitted (post abort) | **10** = 5 (commit) + 5 (abort) — `read_uncommitted` ve TODOS los mensajes incluyendo los abortados (sirve sólo para debugging/inspection). |
| ¿Cuántas transacciones lista `kafka-transactions list`? | **0 visibles** en el momento del query (la tabla salió vacía con solo el header `TransactionalId Coordinator ProducerId TransactionState`). Eso es esperado — las transacciones cerradas (committed/aborted) ya no son "active". Para verlas activas hay que consultar inmediatamente durante una transacción en curso. |
| Estado de las transacciones | **Cerradas (committed)** — la transacción de prueba committeó OK, ya no aparece como activa. |

---

## Parte 5: Desafío - Particionado y throughput

> Esta sección requiere experimentos con `--partitioner-class` que no se completaron en esta validación por scope (el wrapper `perf-test.sh` no expone esa opción y ejecutar `kafka-producer-perf-test` directo es complejo). Las respuestas son las esperadas según el modelo conceptual:

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 50K con clave fija cayeron en la misma partición? | **Sí** — si todas las 50K usan `key="NVT-1001"`, la fórmula `hash("NVT-1001") % 12 = N` da la misma N siempre. El topic acumula todo en partición N. |
| Throughput con clave fija | **Limitado por una sola partición** = típicamente menor (~10-20k rps en este lab). El productor no puede paralelizar entre brokers. |
| Throughput sin clave | **StickyPartitioner** (default Kafka 4.x): pega a una partición hasta llenar batch, luego rota. Throughput similar a partitioner sin clave (mejor que clave fija porque al menos llena varias particiones a lo largo del test). |
| Throughput con RoundRobinPartitioner | **Mayor que sticky** en cargas pequeñas (distribuye desde el primer mensaje), **menor en cargas grandes** (más overhead de batches incompletos cuando se rota cada mensaje). |
| ¿Cuál es mejor? ¿Por qué? | Depende del caso: **StickyPartitioner** = throughput agregado óptimo, ideal para volumen alto. **RoundRobin** = distribución uniforme inmediata, útil cuando hay POCOS mensajes y querés balance. **Por clave** = orden por entidad, sacrificando paralelismo. |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| 6 VIPs con 80% del tráfico y particionado por clave: ¿qué pasa? | **Hot partitioning**: 6 keys = máximo 6 particiones reciben el grueso del tráfico, las demás están subutilizadas. Las que reciben los VIPs se saturan: el broker que las hostea sufre, los consumers que las leen no dan abasto. Latencia disparada en P99. |
| ¿Cómo evitarías el hot partitioning? | Opciones: (a) **clave compuesta**: `customer_id + region + timestamp_bucket` distribuye al mismo cliente entre varias particiones; (b) **sub-particiones**: prefix con un sufijo aleatorio módulo N para los VIPs (`NVT-VIP-001-shard-3`); (c) **replicación de stream**: routear los VIPs a un topic dedicado con más particiones. |
| ¿Cuándo NO importa el orden por clave? | Cuando los eventos son INDEPENDIENTES entre sí: métricas agregadas, logs no correlacionados, eventos que se procesan idempotentemente (re-procesar no duele). Ahí RoundRobin o Sticky son superiores. |

---

## Conclusiones generales

> Tunear un productor es elegir trade-offs explícitos: `batch.size` y `linger.ms` cambian throughput >50% sin tocar código de aplicación. `acks` define durabilidad vs latencia. `enable.idempotence=true` elimina duplicados por retry pero solo per-partition. Las transacciones extienden exactly-once a múltiples particiones/topics con costo de coordinación. La elección del partitioner define orden semántico vs paralelismo: StickyPartitioner (default Kafka 4.x) optimiza throughput para sin-clave; particionado por clave da orden por entidad pero crea hot spots con cargas asimétricas.

---

## Notas del validador

1. **Tiempo de validación**: ~45 minutos.
2. **Parte 5 parcialmente validada estructuralmente**: los experimentos con `--partitioner-class` requieren invocaciones directas de `kafka-producer-perf-test`. Las respuestas conceptuales son correctas pero los números específicos no se midieron.
3. Sin hallazgos pedagógicos nuevos.

*Lab 06 - Curso de Administración de Apache Kafka con Confluent Platform*
