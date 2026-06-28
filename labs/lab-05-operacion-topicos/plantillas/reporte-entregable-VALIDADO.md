# Reporte del Lab 05 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada con datos reales del lab end-to-end. Para referencia del instructor.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: Anatomía de un tópico

| Pregunta | Tu respuesta |
|----------|-------------|
| Tópicos visibles sin `--internal` | **1** — `novatech.fleet.gps` (creado por start-lab.sh) |
| Tópicos visibles con `--internal` | **2** — `__consumer_offsets` + `novatech.fleet.gps` |
| Tópicos internos detectados | `__consumer_offsets` (compactado, 50 particiones por defecto, RF=3) |
| ¿Para qué sirve `__consumer_offsets`? | Topic interno donde Kafka persiste la posición (offset) de cada consumer group por (group, topic, partition). Permite que un consumer group reanude desde donde quedó tras un restart. Es compactado — sólo retiene el último offset committed por clave. |

### Estructura de `novatech.fleet.gps`

| Atributo | Valor |
|----------|-------|
| Particiones | **6** |
| Replication factor | **3** |
| Líder de partición 0 | **1** (en mi corrida; varía por elección) |
| ISR de partición 0 | **1, 2, 3** (las 3 réplicas sincronizadas) |
| ¿Réplicas Out-of-Sync? | **No** — ISR coincide con Replicas en las 6 particiones (todas verdes) |

### 5 configuraciones efectivas observadas

| Config | Valor | ConfigSource |
|--------|-------|--------------|
| `cleanup.policy` | `delete` | DEFAULT_CONFIG |
| `compression.type` | `producer` | DEFAULT_CONFIG (el broker delega al productor) |
| `min.insync.replicas` | `2` | DYNAMIC_DEFAULT_BROKER_CONFIG (override del broker) |
| `retention.ms` | `604800000` (7 días) | (sin synonyms — heredado del default) |
| `segment.bytes` | `1073741824` (1 GiB) | DEFAULT_CONFIG |

> **Nota pedagógica**: `min.insync.replicas` está marcado como DYNAMIC_DEFAULT_BROKER_CONFIG porque el broker tiene un override de cluster (`min.insync.replicas=2`). El default original de Kafka es 1 — pero el cluster del lab fue configurado para exigir mínimo 2 ISR.

---

## Parte 2: Tópicos con personalidad

### `novatech.gps.realtime`

| Atributo | Valor |
|----------|-------|
| Particiones | **12** |
| `retention.ms` efectivo | **3.600.000 ms (1 hora)** |
| `compression.type` efectivo | **`lz4`** |
| ¿Por qué 12 particiones y no 6? | Mayor paralelismo de consumo. La regla práctica: número de particiones ≥ máximo de consumers paralelos esperado. Para alta frecuencia GPS conviene tener "espacio para crecer" en el grupo de consumers sin tener que rehacer el topic. |

### `novatech.audit.events`

| Atributo | Valor |
|----------|-------|
| `retention.ms` efectivo | **7.776.000.000 ms (90 días)** |
| ¿Por qué `gzip`? | Compliance retiene MUCHO tiempo (90 días) y se accede poco. `gzip` comprime más que `lz4` a costa de CPU al producir/consumir. Trade-off correcto para datos cold (mucho almacenamiento, raro acceso). |
| ¿Qué pasa si solo 1 réplica está sincronizada y `min.insync.replicas=2`? | Producer con `acks=all` recibe `NotEnoughReplicasException`. Kafka rechaza la escritura para evitar pérdida — prefiere disponibilidad-de-lectura sobre disponibilidad-de-escritura cuando no se puede garantizar durabilidad. |

### `novatech.vehicle.state`

| Atributo | Valor |
|----------|-------|
| `cleanup.policy` efectivo | **`compact`** |
| ¿Qué hace `min.cleanable.dirty.ratio=0.1`? | Dispara compactación cuando ≥10% del log son keys "viejas" (mensajes superseded por una versión más nueva con la misma key). Default es 0.5 (50%) — bajarlo a 0.1 hace que la compactación corra más seguido (más CPU, menos almacenamiento). |
| Después de 100 mensajes con `key=NVT-1001`, ¿cuántos quedan? | **1 al final de la compactación** (la última versión por key). Pero la compactación es asíncrona — durante varios minutos los 100 pueden coexistir. |
| ¿Cuántos mensajes consumiste justo después? | **5** (los 5 que produjo el ejemplo de la guía). Inmediatamente después de producir, el consumer ve los 5 — la compactación todavía no corrió. Pasados varios minutos, volvería a haber sólo 1 (el último). |

### `novatech.alerts.critical`

| Atributo | Valor |
|----------|-------|
| ¿Se puede escribir si un broker se cae? | **No con `acks=all`** — `min.insync.replicas=3` exige a los 3 brokers vivos. Si cae 1, ISR baja a 2 y producer recibe `NotEnoughReplicasException`. Es **trade-off explícito**: este topic prioriza durabilidad ABSOLUTA sobre disponibilidad. |
| ¿Qué hace `unclean.leader.election.enable=false`? | Si todos los brokers en ISR mueren y queda solo una réplica out-of-sync, Kafka prefiere dejar el partition INDISPONIBLE antes que elegir esa réplica como líder (porque podría haber perdido mensajes). Garantiza no-pérdida. |
| ¿Qué se sacrifica con `min.insync.replicas=3`? | **Disponibilidad para escritura**: con cualquier broker caído, el topic deja de aceptar producciones con `acks=all`. Apropiado solo para datos críticos donde "rechazar antes que perder" es la política correcta (alertas, pagos, transacciones financieras). |

---

## Parte 3: Modificar tópicos en caliente

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió `retention.ms` después de `--alter`? | **Sí**: pasó de 7.776.000.000 ms (90 días, fijado al crear) a 31.536.000.000 ms (365 días). Verificado en describe: `retention.ms=31536000000`. |
| ¿`ConfigSource` cambió a `DYNAMIC_TOPIC_CONFIG`? | **Sí** — al hacer `--alter --add` se aplica un override a nivel de topic, marcado como DYNAMIC_TOPIC_CONFIG. Tras `--delete retention.ms`, el ConfigSource desaparece y vuelve al default del broker (604800000 ms = 7 días). |
| ¿Particiones después de aumentar (12 → ?) | **18** — verificado en describe-topic: PartitionCount: 18. |
| ¿Las nuevas particiones (12-17) tienen mensajes? | **No** (en mi corrida) — los 5000 mensajes producidos antes están en P0-P11. Las nuevas particiones P12-P17 nacen vacías. Las claves NUEVAS pueden ahora caer en P12-P17, pero las viejas claves siguen en sus particiones originales (sin re-hashing). |
| ¿Qué error al intentar disminuir particiones? | `Error while executing topic command : The topic novatech.gps.realtime currently has 18 partition(s); 6 would not be an increase.` Tipo: `org.apache.kafka.common.errors.InvalidPartitionsException`. |
| ¿Por qué Kafka no permite disminuir? | Porque destruiría el orden por clave: si `key=NVT-1001` estaba en partition 14 (de 18) y disminuyés a 6, sus mensajes futuros irían a partition `hash(NVT-1001) % 6` = (digamos) partition 2 — pero los mensajes pasados quedarían en P14, que ya no existe. El orden por entidad se rompe irremediablemente. La solución: crear topic nuevo y migrar. |
| ¿Qué `retention.ms` quedó después de `--delete`? | **604800000** (7 días). Sin synonyms (`synonyms={}`) — ya no es override de topic, es el default del broker que aplica. |

---

## Parte 4: Retención por tiempo en vivo

| Pregunta | Tu respuesta |
|----------|-------------|
| Offset más antiguo disponible tras esperar (`--time -2`) | |
| ¿Se eliminaron mensajes viejos? ¿Por qué `segment.ms` corto importa? | |
| Tamaño en disco de `efimero` vs `resiliente` (Kafbat UI) | |
| ¿Por qué Kafka borra por segmentos completos y no mensaje a mensaje? | |

---

## Conclusiones generales

> Operar tópicos como DBA significa elegir la "personalidad" de cada uno según su caso de uso: retention corta para alta frecuencia, larga para compliance, compactación para "estado actual por entidad", MIR alto para datos críticos. Algunos cambios son baratos en caliente (`retention.ms` vía `--alter`, aumentar particiones), otros prohibidos (disminuir particiones), y otros costosos pero posibles (cambiar RF vía reassign). El override de configs sigue una jerarquía: DYNAMIC_TOPIC_CONFIG > DYNAMIC_DEFAULT_BROKER > STATIC_BROKER > DEFAULT. Siempre consultar `--describe` con synonyms para entender de DÓNDE viene cada valor efectivo.

---

## Notas del validador

1. **Tiempo de validación**: ~50 minutos.

*Lab 05 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
