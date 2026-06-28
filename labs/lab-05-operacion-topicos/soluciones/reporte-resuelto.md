# Lab 04 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Anatomía de un tópico

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Tópicos sin `--internal` | 1 (`novatech.fleet.gps`) |
| Tópicos con `--internal` | 2 o 3 (incluye `__consumer_offsets`) |
| ¿Para qué sirve `__consumer_offsets`? | Tópico interno donde Kafka guarda los offsets actuales de cada consumer group, partición por partición |

### Configuraciones de ejemplo (varían según el broker)

Las configs típicas incluyen: `retention.ms` (DEFAULT_CONFIG = 604800000), `cleanup.policy` (DEFAULT = delete), `compression.type` (DEFAULT = producer), `segment.ms`, `min.insync.replicas`, etc.

---

## Parte 2: Tópicos con personalidad

| Tópico | Particiones | retention.ms | compression | min.insync |
|--------|-------------|--------------|-------------|-----------|
| `novatech.gps.realtime` | 12 | 3600000 (1h) | lz4 | (default) |
| `novatech.audit.events` | 6 | 7776000000 (90d) | gzip | 2 |
| `novatech.vehicle.state` | 6 | (n/a, compact) | (default) | (default) |
| `novatech.alerts.critical` | 3 | -1 (∞) | (default) | 3 |

### Razonamientos clave

- **12 particiones GPS**: alto volumen, alto paralelismo de consumo
- **gzip en audit**: datos accedidos poco frecuentemente, prioriza compresión
- **compact en vehicle.state**: solo importa el último estado por clave
- **`min.insync.replicas=3` con RF=3**: si UN broker se cae, no se puede escribir (la app debe manejar `NotEnoughReplicasException`)
- **`unclean.leader.election.enable=false`**: previene que un follower fuera-de-ISR sea elegido líder, evitando pérdida de datos

### Compactación

Después de 5 mensajes con clave NVT-1001, el alumno **probablemente verá los 5** porque la compactación es asíncrona y no se dispara inmediatamente. En producción, se controla con `min.cleanable.dirty.ratio`, `segment.ms` y el tiempo de espera del log cleaner. Lo correcto es explicar que la compactación garantiza que **eventualmente** quedará solo el último mensaje por clave.

---

## Parte 3: Modificar tópicos en caliente

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿`retention.ms` cambió? | Sí, a 31536000000 (365 días) |
| ¿`ConfigSource`? | Cambió a `DYNAMIC_TOPIC_CONFIG` |
| ¿Sin downtime? | Sí, todo en caliente |
| ¿Particiones tras aumento? | 18 |
| ¿Particiones 12-17 tienen mensajes? | No (todavía). Solo las nuevas escrituras llegarán a ellas según el hash |
| Error al disminuir | "The number of partitions for a topic can only be increased" |
| ¿Por qué? | Disminuir rompería el orden por clave (mensajes existentes en particiones 12-17 no se pueden mover sin perder consistencia) |
| ¿`retention.ms` tras `--delete`? | 604800000 (7 días, el default del broker) |

---

## Parte 4: Producción y consumo masivo

### Métricas típicas (Mac M1/M2, Docker)

- 5.000 mensajes en 5-15 segundos → ~300-1000 msg/seg
- `perf-test` con `acks=all`: 5.000-20.000 msg/seg
- `perf-test` con `acks=1`: 10.000-40.000 msg/seg
- Diferencia: `acks=1` es típicamente 1.5-3x más rápido

### Consumo desde el principio

- Los mensajes NO vienen ordenados globalmente. Vienen ordenados POR PARTICIÓN.
- El alumno verá saltos entre claves (por ejemplo: NVT-3, NVT-3, NVT-7, NVT-7, NVT-3...) porque el consumer va leyendo round-robin entre particiones.

### Consumo de partición específica

- En la partición 3, el alumno verá un subconjunto consistente de claves (mismas o pocas distintas).
- La razón es que `hash(key) % 12` envía cada clave SIEMPRE a la misma partición.

### `acks=all` vs `acks=1`

- `acks=1`: el productor espera solo el ACK del líder. Más rápido pero si el líder muere antes de replicar, se pierde el mensaje.
- `acks=all`: espera ACK de todas las réplicas en ISR. Más lento pero durable.

---

## Parte 5: Desafío

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿Tópico tras eliminar? | No aparece (eliminación efectiva en segundos) |
| ¿RF subió de 1 a 3? | Sí, después del plan de reasignación |
| ¿Por qué no con `--alter`? | Cambiar RF mueve datos físicos entre brokers; debe ser controlado para no saturar la red |
| ¿Más peligroso: particiones o RF? | RF es más peligroso operacionalmente porque genera tráfico masivo de replicación |
| Política para pagos | `min.insync.replicas=2` con RF=3 es lo estándar. Permite tolerar 1 falla y aún escribir. `min.insync.replicas=3` es excesivo (no tolera ninguna falla) |

---

*Solución - Lab 04*
