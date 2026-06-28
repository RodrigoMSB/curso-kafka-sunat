# Parte 2: Niveles de acks

## Objetivo

Comparar empíricamente los 3 niveles de `acks` (0, 1, all) en throughput y durabilidad.

## Contexto

`acks` define cuántas confirmaciones espera el productor antes de considerar un mensaje "enviado":
- `acks=0`: NO espera. "Disparar y olvidar". Máximo throughput, mínima durabilidad.
- `acks=1`: Espera al líder. Si el líder muere antes de replicar, se pierde.
- `acks=all`: Espera al líder + todos los seguidores en ISR. Máxima durabilidad.

---

## Actividad 1: acks=0 (fire and forget)

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --acks 0
```

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| Latencia p99 (ms) | |

---

## Actividad 2: acks=1 (líder confirma)

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --acks 1
```

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| Latencia p99 (ms) | |

---

## Actividad 3: acks=all (todos en ISR)

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --acks all
```

| Métrica | Valor |
|---------|-------|
| records/sec | |
| MB/sec | |
| Latencia p99 (ms) | |

---

## Análisis

| Acks | Throughput | Latencia | Pérdida posible |
|------|-----------|----------|-----------------|
| 0    | | | |
| 1    | | | |
| all  | | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuánto más rápido es acks=0 vs acks=all? | |
| ¿Cuál es el costo de acks=all? | |
| ¿En qué caso usarías acks=0? | |
| ¿Y acks=1? | |
| ¿Y acks=all? | |

---

## Conclusiones

| Concepto | Lo aprendiste midiendo... |
|----------|--------------------------|
| acks=0 | Máximo throughput, riesgo de pérdida |
| acks=1 | Balance: rápido y "razonablemente" durable |
| acks=all | Máxima durabilidad, más lento |
| Trade-off | Cada caso de uso necesita su propio nivel |

---

## Siguiente paso

Continúa con [Parte 3: Idempotencia y duplicados](03-idempotencia-y-duplicados.md).
