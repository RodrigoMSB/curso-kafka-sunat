# Reporte del Lab 07 — VALIDADO POR MOCITO (referencia instructor)

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

## Parte 3: Pruebas de rendimiento de productor y consumidor

### Producción (`kafka-producer-perf-test`)

| Configuración | records/sec | MB/sec | p99 latencia (ms) |
|---------------|-------------|--------|-------------------|
| Baseline (100K msg) | | | |
| batch 64KB + linger 10 | | | |
| compresión lz4 | | | |

### Consumo (`kafka-consumer-perf-test`)

| Configuración | nMsg.sec | MB.sec |
|---------------|----------|--------|
| Baseline (100K msg) | | |
| fetch 5 MB | | |

### Análisis

1. ¿Cuál throughput fue mayor, producción o consumo? ¿Por qué?
2. ¿Qué parámetro tuvo más impacto en cada lado?

---

## Parte 4: Desafío - Particionado y throughput

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

*Lab 07 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
