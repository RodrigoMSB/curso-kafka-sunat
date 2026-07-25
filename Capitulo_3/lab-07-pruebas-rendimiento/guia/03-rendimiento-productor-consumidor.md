# Parte 3: Pruebas de rendimiento de productor y consumidor

## Objetivo

Medir empíricamente el throughput y la latencia de **producción** y de **consumo**, con las herramientas nativas `kafka-producer-perf-test` y `kafka-consumer-perf-test`, observando cómo cambian al variar parámetros del cliente.

## Contexto

NovaTech necesita dimensionar su clúster: ¿cuántos mensajes por segundo aguanta produciendo? ¿Y consumiendo? Las herramientas de perf-test generan carga sintética y miden el resultado, sin escribir código.

| Herramienta | Mide |
|-------------|------|
| `kafka-producer-perf-test` | throughput y latencia de **escritura** |
| `kafka-consumer-perf-test` | throughput de **lectura** (MB/s y msg/s) |

---

## Actividad 1: Medir rendimiento de producción

Genera carga y mide el throughput de escritura:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 100000
```

Observa las métricas finales: records/sec, MB/sec y los percentiles de latencia (p50, p95, p99).

Repite variando parámetros y compara:

```bash
# Batching agresivo
kafka-cli/perf-test.sh novatech.tuning.bench 100000 --batch-size 65536 --linger-ms 10

# Compresión LZ4
kafka-cli/perf-test.sh novatech.tuning.bench 100000 --compression lz4
```

---

## Actividad 2: Medir rendimiento de consumo

El tópico ya tiene mensajes de la actividad anterior. Mide cuán rápido se consumen:

```bash
kafka-cli/consumer-perf-test.sh novatech.tuning.bench 100000
```

Observa: `MB.sec` y `nMsg.sec` (mensajes por segundo) — las métricas del lado consumidor.

Repite con un fetch más grande y compara:

```bash
kafka-cli/consumer-perf-test.sh novatech.tuning.bench 100000 --fetch-size 5242880
```

---

## Actividad 3: Comparar producción vs consumo

Con los números de las dos actividades, razona en el reporte:
- ¿Cuál throughput fue mayor, producción o consumo? ¿Por qué?
- ¿Qué parámetro tuvo más impacto en cada lado?

---

## Siguiente paso

Continúa con [Parte 4: Desafío - Particionado y throughput](04-desafio-particionado-y-throughput.md).
