# Lab 05 — Reporte resuelto (solución de referencia)

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

## Parte 4: Retención por tiempo en vivo

| Pregunta | Respuesta esperada |
|----------|-------------|
| Offset más antiguo disponible tras esperar (`--time -2`) | Avanza (deja de ser 0): tras superar `retention.ms=60s` y rotar el segmento (`segment.ms=10s`), los segmentos viejos se eliminan y el offset más antiguo pasa a ser el inicio del primer segmento sobreviviente. El valor exacto depende de la corrida. |
| ¿Se eliminaron mensajes viejos? ¿Por qué `segment.ms` corto importa? | Sí. Kafka solo elimina **segmentos cerrados**, nunca el segmento activo. Con `segment.ms=10s` los segmentos rotan rápido y quedan elegibles para borrado apenas vence la retención; con el default (7 días de rotación) la retención de 60 s no tendría efecto visible porque todo viviría en el segmento activo. |
| Tamaño en disco de `efimero` vs `resiliente` (Kafbat UI) | `efimero` se mantiene pequeño y estable (pierde datos constantemente por la retención de 60 s); `resiliente` solo crece (retención de 7 días). Los bytes exactos dependen de la corrida. |
| ¿Por qué Kafka borra por segmentos completos y no mensaje a mensaje? | El log es un archivo append-only; borrar mensajes individuales exigiría reescribir el archivo (costoso y con bloqueos). Eliminar un segmento completo es un simple `delete` de archivo: O(1), sin tocar el resto del log. Por eso la granularidad de la retención es el segmento. |

---

*Solución - Lab 05*
