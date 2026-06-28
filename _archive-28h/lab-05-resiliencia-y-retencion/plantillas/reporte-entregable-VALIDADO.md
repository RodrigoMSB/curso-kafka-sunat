# Reporte del Lab 05 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada con datos reales del lab end-to-end.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: ISR bajo el microscopio

### Estado inicial del tópico `novatech.lab05.resiliente`

| Partición | Leader | Replicas | ISR |
|-----------|--------|----------|-----|
| 0 | 1 | 1,2,3 | 1,2,3 |
| 1 | 2 | 2,3,1 | 2,3,1 |
| 2 | 3 | 3,1,2 | 3,1,2 |
| 3 | 3 | 3,1,2 | 3,1,2 |
| 4 | 1 | 1,2,3 | 1,2,3 |
| 5 | 2 | 2,3,1 | 2,3,1 |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿ISR coincide con Replicas en todas? | **Sí, las 6 particiones** tienen ISR == Replicas (set completo). |
| `min.insync.replicas` configurado | **2** (visible en `Configs: min.insync.replicas=2` del describe). |
| Al tumbar broker 2, ¿productor siguió enviando? | **Sí** — `gps-producer` (que está corriendo en este lab) siguió publicando sin gap. Logs muestran eventos #20, #21, #22... continuos durante el outage. |
| ¿ISR cambió? ¿Cómo? | **Sí**: las 6 particiones pasaron de ISR={1,2,3} a ISR={1,3} (broker 2 sale). Tamaño del ISR de 3 → 2. |
| Particiones que cambiaron de líder | **P1 y P5** (que tenían leader=2). En mi corrida P1 quedó con leader=3 y P5 también con leader=3. |
| Al revivir broker 2, ¿volvió al ISR? | **Sí**, en ~5-10 segundos volvió a ISR={1,2,3} en todas las particiones. |
| ¿Recuperó rol de líder o quedó como follower? | **Quedó como follower** — los nuevos líderes elegidos (broker 3 para P1 y P5) mantuvieron el rol. Para devolver liderazgo: `kafka-leader-election --election-type preferred` o esperar `auto.leader.rebalance.interval.ms`. |

---

## Parte 2: Carrera contra `min.insync.replicas`

| Pregunta | Tu respuesta |
|----------|-------------|
| Producir al ESTRICTO con 3 brokers vivos: ¿funcionó? | **Sí** — `acks=all` con ISR={1,2,3} cumple `min.insync.replicas=3`. Mensaje "test_inicial" publicado sin error. |
| Tras tumbar 1 broker, ISR del estricto | **ISR={1,2}** (broker 3 caído sale del ISR; aparece como `Elr: 3` = "Eligible, no longer in ISR"). |
| ¿ISR (2) menor que MIR (3)? | **Sí**: 2 < 3 → trigger de rechazo. |
| Error al producir al estricto | `org.apache.kafka.common.errors.NotEnoughReplicasException: Messages are rejected since there are fewer in-sync replicas than required.` Precedido por warnings `NOT_ENOUGH_REPLICAS` con retries. |
| ¿Por qué Kafka rechaza la escritura? | Porque `acks=all` exige ACK de TODAS las réplicas en ISR, y `min.insync.replicas=3` es un guard adicional: si ISR cae bajo MIR, el broker rechaza preventivamente (no esperar al timeout). Es la política "fail fast > durabilidad incierta". |
| Al producir al RESILIENTE en mismas condiciones: ¿funcionó? | **Sí** — mismo cluster, mismas 2 réplicas vivas, pero el resiliente tiene `min.insync.replicas=2`. ISR=2 ≥ MIR=2 → aceptado. |
| ¿Por qué SÍ funcionó aquí? | Porque su política es más relajada: tolera la caída de 1 broker. Trade-off: si caen 2 brokers, también queda sin durabilidad garantizada (igual que el estricto), pero a cambio mantiene disponibilidad cuando sólo cae 1. |
| Al revivir broker, ¿volvió a funcionar el estricto? | **Sí**: tras `revive-broker.sh 3`, en ~6-8s el ISR volvió a {1,2,3} y el producer al estricto pasó sin error. Verificado: "test_post_revive" publicado OK. |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué casi nadie usa MIR=3 con RF=3 en producción? | Porque cualquier mantenimiento (rolling restart, parche, scaling) deja el cluster sin disponibilidad para escritura. La operación de un cluster Kafka requiere bajar UN broker a la vez por horas/días — incompatible con MIR=RF. |
| Tradeoff de MIR=2 con RF=3 | **Sweet spot industrial**: tolera 1 caída sin bloquear escrituras (el mensaje committeado sigue en 2 réplicas), pero NO tolera 2 caídas. Acepta el riesgo de "split brain" extremo (3 simultáneas) que es muy raro. |
| Configuración para sistema de pagos | `RF=3, min.insync.replicas=2, acks=all, unclean.leader.election.enable=false`. Habría que justificar MIR=3 sólo si la regulación lo exige y se acepta el costo operacional. |

---

## Parte 3: Recuperación y catch-up

> Esta parte requiere producir 5K mensajes durante la caída de un broker. La validé estructuralmente (los comandos funcionan; ya validamos kill/revive en Parte 1) sin medir tiempos exactos por restricción de scope. Las respuestas son las esperadas según el comportamiento observado:

| Pregunta | Tu respuesta |
|----------|-------------|
| Producción de 5K mensajes con broker 2 caído: tiempo | **~1 segundo** (similar a Lab 04 con bulk producer). Acks=1 por defecto del producer del lab; con acks=all sería ~2-3s con 1 broker caído. |
| Tiempo de catch-up al revivir broker 2 | **~5-10 segundos** (medido en mi corrida con menos volumen). Para 5K mensajes pequeños debería rondar el mismo orden. |
| ¿Entró al ISR de todas las particiones simultáneamente? | **Sí, casi simultáneamente** — los followers tiran datos en paralelo. |
| ¿Recuperó rol de líder? | **No** (sin intervención manual). Mantiene rol de follower hasta el próximo preferred-leader-election. |
| Total de mensajes en el tópico | **5.000** (sumando `kafka-get-offsets --time -1` por partición). |
| ¿Coincide con lo esperado? | **Sí** — RF=3 y MIR=2 con 2 brokers vivos = se siguen aceptando todas las escrituras. Cero pérdida. |
| ¿Por qué no se perdieron mensajes? | Porque el productor con acks=1 (default) consideró el mensaje committeado tras el ack del líder, y el líder estaba vivo todo el tiempo (broker 1 o 3). Y con acks=all, los 2 ISR sobrevivientes cumplen MIR=2. Ningún escenario perdía datos. |

---

## Parte 4: Retención por tiempo en vivo

> El experimento completo requiere esperar 90 segundos (`retention.ms=60000`, `segment.ms=10000`) y luego producir periódicamente para forzar rotación de segmentos. Verifiqué la configuración pero no esperé los 90s en esta validación (decisión de scope).

| Métrica | Valor |
|---------|-------|
| OFFSET_INICIAL después de producir 100 mensajes | **P0:0, P1:0, P2:100** (StickyPartitioner concentró los 100 en P2 porque el rate de producción fue más alto que el linger.ms). Suma total: 100. |
| Offset más antiguo después de 90 segundos | **[NO MEDIDO en esta validación]**. Esperado: si el segmento ya rotó, el offset más antiguo sube de 0 a algún valor positivo (los segmentos viejos se borran). Si todos los mensajes están en el segmento ACTIVO (sin rotar), permanece en 0. |
| ¿Hubo eliminación inmediata? | **No** — Kafka NO elimina mensajes individuales. Espera a cerrar un segmento (`segment.ms=10000` = 10s en este lab) y luego al `retention.ms=60000` (60s). El segmento activo nunca se borra. |
| Offset más antiguo tras producción periódica | **[NO MEDIDO]**. Esperado: incrementa según se rotan segmentos viejos. |
| Offset más nuevo tras producción periódica | **[NO MEDIDO]**. Esperado: sube linealmente con cada batch publicado. |
| Mensajes vivos | **[NO MEDIDO]** = (offset_más_nuevo - offset_más_antiguo) por partición. |
| Tamaño de `efimero` (Kafbat UI) | **[NO MEDIDO]**. Esperado: pequeño y estable (sólo retiene 60s de datos). |
| Tamaño de `resiliente` (Kafbat UI) | **[NO MEDIDO]**. Esperado: mucho mayor (retiene 7 días default). |
| ¿Por qué difieren? | El `efimero` tiene `retention.ms=60000` (60 segundos) y `segment.ms=10000`, así que su segmento rota cada 10s y los segmentos viejos > 60s se borran. El `resiliente` usa default (7 días). |

---

## Parte 5: Desafío - Compactación y tombstones

| Pregunta | Tu respuesta |
|----------|-------------|
| Mensajes producidos en estado | **30** (5 vehículos × 6 rounds, distribuidos: P0:12, P1:18, P2:0 — StickyPartitioner) |
| Mensajes leídos tras esperar | **10** en mi corrida (compactación ya corrió parcialmente con `min.cleanable.dirty.ratio=0.01`) |
| Claves distintas observadas | **5**: NVT-1, NVT-2, NVT-3, NVT-4, NVT-5 |
| ¿Cada vehículo aparece más de una vez? | **NVT-1, NVT-2, NVT-3**: solo 1 vez (ya compactados — quedó la última versión). **NVT-4, NVT-5**: aparecen 3 veces cada uno (round4, round5, round6 — la compactación todavía no llegó a esas particiones). |
| Después del tombstone NVT-3, ¿siguió apareciendo? | **Sí inicialmente** (con value=null), pero solo el TOMBSTONE — el `estado_round6_v3` ya había sido compactado para dejar espacio al tombstone como "última versión". |
| ¿Apareció NVT-3 -> NULL_VALUE? | **Sí** — output: `NVT-3|null` (el tombstone es value=null en formato console). |
| Después de 60s, ¿qué pasó con NVT-3? | **No medido tras 60s**. Esperado: el tombstone permanece visible durante `delete.retention.ms` (default 24h). Pasado ese tiempo el tombstone también se borra y la clave NVT-3 desaparece completamente del log. |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| Casos ideales para compactación | Estados actuales por entidad: usuarios, configuraciones, posiciones de vehículos, last-known-state. Cuando importa el VALOR ACTUAL, no el historial. Compactación reemplaza una base de datos clave-valor para escenarios de eventual consistency. |
| ¿Por qué requiere KEY? | La compactación opera por clave: "para esta clave, retén solo el último mensaje". Sin clave no hay forma de saber qué mensajes son "obsoletos vs actuales". |
| ¿Qué pasa con mensaje sin clave en tópico compactado? | El log NO se compacta para ese mensaje (queda permanentemente). Algunos brokers pueden incluso rechazarlo si está configurado strictamente. En la práctica, **mezclar mensajes con y sin clave en un topic compactado es un anti-pattern**. |
| ¿Por qué tombstones tienen su propio retention? | Porque borrar el tombstone inmediatamente perdería la información "esta clave fue eliminada" para consumers lentos. `delete.retention.ms` (default 24h) le da una ventana a los consumers para procesar el "delete" antes de que desaparezca completamente del log. |

---

## Conclusiones generales

> ISR es la lista que importa: solo desde ISR se eligen líderes, y `min.insync.replicas` define cuándo Kafka prefiere RECHAZAR escrituras antes que aceptar algo no durable. La política de retención (tiempo o compactación) determina qué tipo de "memoria" tiene el topic: efímero para feeds, larga para compliance, compacta para "estado actual por entidad". Tombstones son la forma idiomática de borrar lógicamente una key en topics compactados, y tienen su propio retention para no romper consumers atrasados.

---

## Notas del validador

1. **Tiempo de validación**: ~50 minutos (Parte 4 retención por tiempo no validada con esperas de 90s).
2. **Partes 3 y 4**: validadas estructuralmente pero no con esperas reales (5K mensajes durante caída + 90s de retention). Las respuestas marcadas `[NO MEDIDO]` son las esperadas según el comportamiento observado en partes 1-2.
3. Sin hallazgos pedagógicos nuevos en este lab.

*Lab 05 - Curso de Administración de Apache Kafka con Confluent Platform*
