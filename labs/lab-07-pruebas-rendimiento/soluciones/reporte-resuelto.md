# Lab 07 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Tuning de batch.size y linger.ms

### Métricas típicas (Mac M1/M2 con Docker)

| Configuración | records/sec | Latencia p99 |
|---------------|-------------|--------------|
| Baseline (defaults) | 5.000 - 15.000 | 50-200 ms |
| Batch 64KB + linger 10ms | 20.000 - 60.000 | 30-100 ms |
| Compresión LZ4 | 10.000 - 25.000 | 50-150 ms |
| Combinación pro (todo activado) | 50.000 - 100.000+ | 30-80 ms |
| Máximo extremo (1MB batch + zstd) | 80.000 - 150.000+ | 100-500 ms |

### Reflexión

- **Mejor throughput**: combinación pro con batch grande + linger + compresión.
- **Peor latencia**: máximo extremo (1MB batch + 100ms linger). El batch demora más en cerrarse.
- **Trade-off**: linger.ms agrega latencia por diseño (espera para acumular). Más allá de cierto punto, no compensa.
- **NovaTech GPS**: throughput alto, latencia tolerable (datos en streaming, no en milisegundos críticos) → batch + linger 10-50ms + LZ4.
- **Pagos en tiempo real**: latencia crítica, throughput menos. Batch chico, linger=0, sin compresión adicional.

---

## Parte 2: Niveles de acks

### Métricas típicas

| Acks | Throughput | Latencia p99 | Pérdida |
|------|-----------|--------------|---------|
| 0    | 60K-100K msg/s | 5-20 ms | Sí (productor cae sin saber) |
| 1    | 30K-60K msg/s | 20-50 ms | Sí (líder muere antes de replicar) |
| all  | 15K-30K msg/s | 50-150 ms | Solo si caen TODAS las réplicas en ISR |

### Reflexión

- **acks=0 es 3-5x más rápido que acks=all**.
- **acks=0**: métricas, telemetría no crítica, logs de aplicación.
- **acks=1**: workloads donde la pérdida ocasional es aceptable (eventos de UI, clics).
- **acks=all**: pagos, auditoría, eventos críticos.

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

> Las tablas de métricas dependen del hardware; lo evaluable es que el alumno **justifique con sus propios números**. Respuestas modelo:

1. **¿Cuál throughput fue mayor, producción o consumo? ¿Por qué?** Típicamente el **consumo**: leer es secuencial y se sirve mayormente desde el page cache del SO (zero-copy hacia la red), mientras que producir paga replicación (RF 3), acuse según `acks` y la construcción de batches. En hardware con disco lento la brecha se agranda. El resultado exacto depende de la corrida — lo importante es justificarlo con los números medidos.
2. **¿Qué parámetro tuvo más impacto en cada lado?** En producción, el par `batch.size` + `linger.ms` (más batching = menos requests = más throughput, a costa de latencia) y la compresión (`lz4` suele subir los MB/s efectivos). En consumo, `fetch-size` (fetches más grandes = menos round-trips). La respuesta del alumno debe citar sus propias mediciones.

---

## Parte 4: Desafío

### Particionado por clave fija

- Las 50K con la misma clave caen en UNA partición → un solo broker líder maneja todo el tráfico.
- Throughput cae significativamente vs distribución uniforme.

### RoundRobinPartitioner

- Distribuye estrictamente. En general da throughput similar a sticky pero con peor latencia (más overhead de coordinación de batches por partición).

### Hot partitioning

- 6 VIPs con 80% del tráfico → 6 particiones quedan saturadas, las demás ociosas.
- **Soluciones**: usar particionador custom que detecte la "calidez" de la clave y la distribuya, o cambiar el esquema de claves (concatenar VIP con timestamp para distribuir).

### Cuándo no importa orden por clave

- Métricas agregadas (sumas, contadores) — el orden no afecta el resultado.
- Eventos idempotentes con timestamp.
- Cuando el procesamiento es por batch, no por evento.

---

*Solución - Lab 07*
