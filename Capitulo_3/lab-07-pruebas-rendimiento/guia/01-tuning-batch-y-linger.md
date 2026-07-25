# Parte 1: Tuning de batch.size y linger.ms

## Objetivo

Medir empíricamente cómo `batch.size` y `linger.ms` afectan el throughput. Encontrar el "sweet spot" para el caso de uso de NovaTech.

## Contexto

Por defecto, el productor de Kafka envía mensajes uno por uno (`linger.ms=0`). Cada batch se cierra apenas tiene un mensaje. Esto es ineficiente: cada envío tiene overhead de red y de procesamiento.

Subir `batch.size` y `linger.ms` permite **acumular** mensajes y enviarlos en grupos. El throughput sube, la latencia individual también sube ligeramente.

---

## Actividad 1: Baseline — sin tuning

Mide el throughput SIN ninguna optimización:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

Anota los valores de la salida:

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| Latencia media (ms) | |
| Latencia p99 (ms) | |

---

## Actividad 2: Batch grande + linger 10ms

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 \
    --batch-size 65536 --linger-ms 10
```

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| Latencia media (ms) | |
| Latencia p99 (ms) | |
| % mejora vs baseline | |

---

## Actividad 3: Compresión LZ4

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 \
    --compression lz4
```

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| % mejora vs baseline | |

---

## Actividad 4: Combinación pro

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 \
    --batch-size 65536 --linger-ms 10 --compression lz4
```

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| % mejora vs baseline | |

---

## Actividad 5: ¿Y si subo TODO al máximo?

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 100000 \
    --batch-size 1048576 --linger-ms 100 --compression zstd
```

| Métrica | Valor |
|---------|-------|
| records/sec | |
| Latencia p99 (ms) | |
| ¿Subió el throughput o la latencia? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué config dio mejor throughput? | |
| ¿Qué config dio peor latencia? | |
| ¿Hay un trade-off entre throughput y latencia? | |
| Para NovaTech (eventos GPS), ¿qué priorizarías? | |
| Para pagos en tiempo real, ¿qué priorizarías? | |

---

## Conclusiones

| Concepto | Lo aprendiste midiendo... |
|----------|--------------------------|
| `batch.size` | El throughput sube cuando agrupas más mensajes |
| `linger.ms` | Esperar un poco antes de enviar mejora batching |
| `compression.type` | LZ4/ZSTD reducen bytes en red |
| Trade-off | Más throughput = más latencia (a veces) |

---

## Siguiente paso

Continúa con [Parte 2: Niveles de acks](02-niveles-de-acks.md).
