# Lab 06 — Reporte resuelto (solución de referencia)

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

## Parte 3: Idempotencia

### Comportamiento esperado

- **Naive**: en local sin congestión, lo más probable es que el alumno NO vea duplicados con timeout=100ms y red local. Para forzarlos, bajar a 50ms o agregar latencia con `tc`.
- **Idempotente**: SIEMPRE produce exactamente N mensajes nuevos.

### Configs forzadas

`enable.idempotence=true` requiere:
- `acks=all`
- `retries=Integer.MAX_VALUE`
- `max.in.flight.requests.per.connection<=5`

Si forzas `acks=1` con idempotencia, el productor **falla al iniciar** con: `ConfigException: Must set acks to all in order to use the idempotent producer`.

### Garantías

- **Idempotencia garantiza**: no-duplicados dentro de UN productor + UNA partición + UNA sesión.
- **NO garantiza**: no-duplicados a través de sesiones (productor reiniciado), ni a través de múltiples particiones.
- **Para exactly-once cross-partition**: necesitas transacciones.

---

## Parte 4: Transacciones

### Comportamiento esperado

- Con COMMIT: ambos `read_committed` y `read_uncommitted` ven los mensajes.
- Con ABORT (en la implementación pedagógica de este lab): el comportamiento puede no ser perfecto desde CLI; los alumnos verían diferencia entre los dos isolation levels si usaran código de aplicación con `producer.abortTransaction()`.

### Limitación reconocida

`kafka-console-producer` no soporta control completo de transacciones. `kafka-verifiable-producer` tampoco maneja abort directamente. Esta parte del lab es **conceptual**: el alumno aprende QUÉ son las transacciones y cómo se inspeccionan, no necesariamente cómo programarlas.

---

## Parte 5: Desafío

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

*Solución - Lab 06*
