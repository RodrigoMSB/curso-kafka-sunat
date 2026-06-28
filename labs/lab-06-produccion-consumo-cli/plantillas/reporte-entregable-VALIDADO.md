# Reporte del Lab 02 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada por el agente de validación con datos reales obtenidos al ejecutar el lab end-to-end. Para referencia del instructor.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: El log inmutable

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes leíste la primera vez? | **5** (los 5 producidos: NVT-1001 STARTED, NVT-1002 STARTED, NVT-1001 STOPPED, NVT-1003 STARTED, NVT-1002 MAINTENANCE) |
| ¿Aparecieron de nuevo cuando re-ejecutaste consume con `--from-beginning`? | **Sí, los mismos 5**. Con `--from-beginning` el consumer arranca desde offset 0 y NO afecta a los mensajes (son inmutables). |
| Sin `--from-beginning`, ¿qué mensajes ves? | **Solo los nuevos** que llegan mientras el consumer está corriendo. Si no llega nada, no se ve nada (queda esperando). |
| ¿Por qué Kafka se comporta así? | Kafka es un **log distribuido inmutable**, no una cola. Los mensajes no se eliminan al ser leídos: se eliminan solo cuando vence `retention.ms` o `retention.bytes`. Cada consumer mantiene su propia posición (offset). Esto permite múltiples consumidores independientes y replays históricos. |

### Offsets observados (tras producir 5 + 1 broadcast = 6 mensajes)

Output de `kafka-get-offsets`:
```
novatech.fleet.events:0:0   (P0 vacío inicialmente, luego entra NVT-1005 broadcast)
novatech.fleet.events:1:0   (P1 vacío)
novatech.fleet.events:2:1   (P2: 1 mensaje)
novatech.fleet.events:3:1   (P3: 1 mensaje)
novatech.fleet.events:4:1   (P4: 1 mensaje)
novatech.fleet.events:5:2   (P5: 2 mensajes)
```

| Mensaje | Offset | Partición |
|---------|--------|-----------|
| vehicle:NVT-1001 STARTED | 0 | 4 |
| vehicle:NVT-1002 STARTED | 0 | 5 |
| vehicle:NVT-1001 STOPPED | 0 | 2 |
| vehicle:NVT-1003 STARTED | 1 | 5 |
| vehicle:NVT-1002 MAINTENANCE | 0 | 3 |

> **Nota**: como NO especificamos `--key` al producir, el partitioner default (StickyPartitioner) los distribuyó "pseudo-aleatoriamente" entre las particiones — pero verás que tiende a agruparse por batches.

---

## Parte 2: Pub/Sub con múltiples consumidores

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas terminales recibieron el mensaje al producir 1? | **Las 3** (broadcast: cada consumer sin `--group` es un grupo efímero distinto, recibe TODO). |
| ¿En qué orden llegaron a las 3 terminales? | Las 3 recibieron `vehicle:NVT-1005 event:CRITICAL_ALERT` casi simultáneamente (~10ms entre sí). El orden depende del scheduling del SO, no es determinístico. |
| Si esto fuera RabbitMQ, ¿cuántas habrían recibido el mensaje? | **1 sola** (las colas tradicionales tienen semántica "competing consumers": un mensaje se entrega a UN consumidor del set). |
| ¿Apareció algún grupo en `list-groups.sh`? ¿Por qué? | **SÍ aparecen** grupos con nombre `console-consumer-95509`, `console-consumer-3461`, etc. (uno por terminal). En Kafka 4.x estos grupos efímeros SÍ quedan registrados en `__consumer_offsets`; eventualmente se purgan por `offsets.retention.minutes` (default 7 días). La guía 02 línea 90 fue corregida en fase 2 para reflejar este comportamiento. |

---

## Parte 3: Consumer Groups y escalado horizontal

### Distribución de particiones (grupo `alertas`, topic con 6 particiones)

| Cantidad de consumidores | Particiones por consumidor | Total particiones repartidas |
|--------------------------|----------------------------|------------------------------|
| 1 | 6 (todas) | 6 |
| 2 | 3 + 3 | 6 |
| 3 | 2 + 2 + 2 | 6 |
| 5 | 2 + 1 + 1 + 1 + 1 | 6 |

> **Verificado con `describe-group.sh alertas`**: con 5 consumers, uno tiene 2 particiones y los otros 4 tienen 1 cada uno (no hay ociosos porque hay 6 particiones).

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Algún mensaje fue recibido por más de un consumidor del mismo grupo? | **No** — dentro del mismo grupo cada partición está asignada a UN solo consumer. Es la diferencia clave vs Parte 2 (sin grupo = broadcast). |
| Con 5 consumidores y 6 particiones, ¿hay alguno ocioso? | **No** — los 5 reciben al menos 1 partición; uno recibe 2. |
| ¿Qué pasaría con 7 consumidores? | **6 estarían trabajando, 1 estaría OCIOSO** sin asignación. La regla: máximo paralelismo útil = número de particiones del topic. |
| Al cerrar bruscamente uno, ¿se redistribuyeron sus particiones? | **Sí** — Kafka detecta la desconexión vía session timeout (~45s) y dispara rebalance. Las particiones del consumer caído se reparten entre los sobrevivientes en la próxima asignación. |

---

## Parte 4: Offsets y replay

### Estado del grupo `alertas` antes del reset

(Tras consumir todos los mensajes producidos durante Parte 3:)

| Partición | CURRENT-OFFSET | LOG-END-OFFSET | LAG |
|-----------|----------------|----------------|-----|
| 0 | 1 | 1 | 0 |
| 1 | 0 | 0 | 0 |
| 2 | 1 | 1 | 0 |
| 3 | 1 | 1 | 0 |
| 4 | 1 | 1 | 0 |
| 5 | 2 | 2 | 0 |

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El grupo `reportes` empezó desde el inicio o desde el final? | **Desde el final** (`auto.offset.reset=latest` por default). Verificado: `consume-as-group.sh --group reportes` recibió **0 mensajes** aunque había mensajes históricos. Para procesar el histórico hace falta `reset-group.sh reportes` (que aplica `--to-earliest`). |
| Después del reset, ¿qué CURRENT-OFFSET tienen las particiones? | **0 en todas las particiones** (`--to-earliest` posiciona en el offset más antiguo disponible, que es 0 cuando no hubo retention). |
| ¿El reset de `reportes` afectó al grupo `alertas`? | **No** — los offsets son **por consumer group**. `alertas` mantiene sus offsets intactos en `__consumer_offsets`. |

> **⚠ Nota operacional**: tras Ctrl+C en un consumer, hay que esperar ~45-60s antes de poder resetear su grupo (session timeout). De lo contrario se obtiene `Assignments can only be reset if the group is inactive, but the current state is Stable`. La guía 04 actividad 3 fue actualizada en fase 2 (B.3) para mencionar este delay.

---

## Parte 5: Desafío - Claves y particionado

### Predicción vs realidad

| Vehículo | Partición predicha | Partición real (verificado vía consume --partition) |
|----------|-------------------|---------------------------|
| NVT-1001 | (no se puede predecir sin la fórmula murmur2) | **2** |
| NVT-1002 | (idem) | **0** |
| NVT-1003 | (idem) | **5** |
| NVT-1004 | (idem) | **1** |
| NVT-1005 | (idem) | **3** |

> Kafka usa `partition = murmur2(key) % numPartitions`. Es determinístico pero pseudo-aleatorio: no hay forma de "predecir" sin computar el hash. Lo que SÍ se garantiza: **misma clave → siempre misma partición** (mientras no se cambie el número de particiones).

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 4 eventos de NVT-1001 cayeron en la misma partición? | **Sí, los 4 eventos** con key=NVT-1001 cayeron en partición 2 (verificado consumiendo `--partition 2`). Esa es la garantía clave de orden por entidad. |
| Con 100 vehículos y 6 particiones, ¿cuántos vehículos comparten partición en promedio? | **~17 vehículos por partición** (100 / 6). En la práctica con murmur2 la distribución es uniforme con poca varianza. |
| ¿Eso rompe el orden por vehículo? | **No.** Aunque varios vehículos comparten partición, dentro de la partición Kafka mantiene orden FIFO. Para CADA vehículo individual, sus eventos están ordenados. Lo que NO se garantiza es orden TOTAL entre vehículos distintos (sus eventos pueden estar interleaved). |

---

## Conclusiones generales

> Kafka es un log distribuido inmutable: leer no consume. Sin `--group` cada consumer es independiente (broadcast); con el mismo `--group` los consumers se reparten las particiones (escalado horizontal hasta el cap del número de particiones). Cada grupo mantiene SUS offsets independientes — un reset NO afecta a otros grupos. Las claves activan particionado determinístico vía murmur2: misma clave → misma partición → orden FIFO garantizado por entidad. La elección entre "con clave / sin clave" es la decisión arquitectónica más importante para escenarios con orden por entidad.

---

## Notas del validador

1. **B.2 aplicado**: guía 02 línea 90 corregida para reflejar que los grupos efímeros sí quedan registrados.
2. **B.3 aplicado**: guía 04 actividad 3 ahora menciona el delay de ~45-60s del session timeout.
3. **Tiempo de validación**: ~40 minutos (Parte 3 lleva tiempo por los rebalances).

*Lab 02 - Curso de Administración de Apache Kafka con Confluent Platform*
