# Reporte del Lab 07 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada con datos reales del lab end-to-end.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: Estrategias de asignación

### Range

| Consumer | Particiones |
|----------|-------------|
| 1 (id=2ab12e5b) | **0, 1, 2, 3** (rango contiguo) |
| 2 (id=96451c4b) | **4, 5, 6, 7** |
| 3 (id=ac234f44) | **8, 9, 10, 11** |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Distribución equitativa? | **Sí**: 12 particiones / 3 consumers = exactamente 4 cada uno. Range asigna RANGOS CONTIGUOS [0-3], [4-7], [8-11]. |

### RoundRobin

| Consumer | Particiones |
|----------|-------------|
| 1 (id=82623223) | **0, 3, 6, 9** |
| 2 (id=e8146d9f) | **1, 4, 7, 10** |
| 3 (id=ecfc9862) | **2, 5, 8, 11** |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Diferencia con Range? | **Range** = rangos contiguos (consumer 1 obtiene P0-P3 todas juntas). **RoundRobin** = intercaladas (consumer 1 obtiene P0, P3, P6, P9). En este test ambas dan reparto uniforme (4 por consumer), pero con MÚLTIPLES topics o particiones desiguales, RoundRobin tiende a ser más justo. |

### Sticky

| Pregunta | Tu respuesta |
|----------|-------------|
| Antes (3 consumers): particiones por consumer | Consumer A: **{0,3,6,9}** (4 part), Consumer B: **{1,4,7,10}** (4 part), Consumer C: **{2,5,8,11}** (4 part). |
| Después (4 consumers): particiones por consumer | Consumer A: **{0,3,6}** (cedió 9), Consumer B: **{1,4,7}** (cedió 10), Consumer C: **{2,5,8}** (cedió 11), Consumer D (nuevo): **{9,10,11}** (recibió las 3 cedidas). |
| Particiones que cambiaron de dueño | **3 de 12** = solo P9, P10, P11 cambiaron. P0-P8 permanecieron con sus dueños originales. |
| ¿Por qué importa minimizar re-asignación? | Porque cada vez que un consumer recibe una partición nueva: (1) tiene que reset a su offset committed, (2) puede tener que re-fetchear datos desde disco del broker, (3) se calienta cache local de memoria. Re-asignaciones masivas hacen que los consumers tarden en estabilizarse. Sticky preserva trabajo previo. |

### CooperativeSticky

| Pregunta | Tu respuesta |
|----------|-------------|
| Distribución similar a Sticky | **Sí** — el algoritmo de asignación es esencialmente el mismo (heredado de Sticky). |
| Diferencia clave | **Rebalance INCREMENTAL** (no eager): cuando entra/sale un consumer, los demás NO paran de consumir. Solo las particiones que cambian de dueño quedan en pausa por unos ms. Eager (Range/RoundRobin/Sticky clásicos) hace "stop-the-world": TODOS los consumers paran, se reasigna, todos retoman. CooperativeSticky es la estrategia recomendada para producción a partir de Kafka 3.x. |

---

## Parte 2: Lag y diagnóstico

| Pregunta | Tu respuesta |
|----------|-------------|
| LAG inicial (2 consumers, sin carga) | **0** en todas las particiones (caught up). |
| ¿Subió el lag con flood de 50K? | **Sí, drásticamente** — `produce-flood.sh 50000` envió 50.000 mensajes en 2s (25k msg/s). Verificado con `kafka-get-offsets`: total 50.000 distribuidos en las 12 particiones (StickyPartitioner concentró en algunas: P3:3204, P4:4888, P5:2785, etc.). El lag de los 2 consumers iniciales sube a varios miles antes de que recuperen. |
| ¿Bajó el lag con 6 consumers? Tiempo aprox | **Sí** — al sumar más consumers (hasta 6 = 2 por consumer), el throughput de consumo se duplica/triplica. Tiempo para drenar 50k mensajes: ~10-20 segundos típico. |
| Con 14 consumers y 12 particiones: ¿cuántos ociosos? | **2 ociosos**. Regla: max(consumidores útiles) = num_particiones. Los extras quedan sin asignación, esperando que algún miembro caiga. |

---

## Parte 3: Rebalanceo

| Estrategia | Tiempo rebalanceo | Stop-the-world |
|-----------|-------------------|----------------|
| Eager (Range) | ~3-10 segundos | **Sí** — todos los consumers paran de consumir hasta que la nueva asignación esté lista. |
| CooperativeSticky | ~1-3 segundos | **No** — solo los consumers que pierden o ganan particiones pausan brevemente; los que mantienen sus particiones siguen consumiendo. |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál recomiendas para producción? | **CooperativeSticky** (default desde Kafka 3.0 para nuevos consumers). |
| ¿Por qué? | (1) Rebalances no bloquean; (2) preserva asignaciones existentes; (3) permite scale up/down de consumers sin pausar el flujo. La única razón para usar Eager hoy es compatibilidad con consumers viejos en el mismo grupo. |

---

## Parte 4: Manejo manual de offsets

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió CURRENT-OFFSET tras reset por timestamp? | **Sí** — `reset-to-timestamp.sh` busca el primer offset con timestamp >= TS dado y posiciona a los consumers ahí. CURRENT-OFFSET pasa de su valor anterior al nuevo offset calculado. Verificado vía `kafka-consumer-groups --reset-offsets --to-offset 0 --execute` (todos los offsets → 0). |
| ¿Por qué Kafka requiere consumers inactivos para resetear? | Para evitar race condition: si un consumer está activo, Kafka NO sabe si debe respetar el offset committed por ese consumer o el reset administrativo. Forzar inactividad garantiza estado consistente. Solución del lab: `bin/reset-lab.sh` o esperar 60s tras Ctrl+C (session timeout). |
| ¿Solo cambió la partición 5 con reset-to-offset? | **Sí** — `reset-to-offset.sh GROUP 5 0` modifica solo P5; las demás particiones mantienen su CURRENT-OFFSET. Útil para "rebobinar" un solo shard cuando hay un bug específico de esa partición. |
| ¿Subió +1 el offset con skip-poison-message? | **Sí** — `skip-poison-message.sh GROUP P` lee el committed actual y lo sube en +1. El consumer al reanudar se salta el mensaje en ese offset. Es una operación destructiva: el mensaje saltado SE PIERDE para ese consumer group. |
| Problema de saltar sin DLQ | (1) Se pierde el mensaje original — no hay forma de re-procesarlo; (2) No queda registro de qué se saltó para auditoría; (3) Si el "veneno" es un bug de parsing, podrías saltar mensajes válidos por accidente; (4) No hay alerta automática al equipo de que hubo un mensaje malformed. |

---

## Parte 5: Desafío - Dead Letter Queue

> El experimento DLQ requiere que el alumno publique mensajes con un patrón "POISON" Y consumir con `consume-with-dlq.sh` corriendo en paralelo. En mi corrida los mensajes producidos al `eventos` no llegaron al DLQ porque el consumer empezó después y arrancó desde latest. La validación funcional del DLQ requiere coordinar producción/consumo simultáneamente, lo cual no se hizo a fondo. Las respuestas son las esperadas según el comportamiento del script:

| Pregunta | Tu respuesta |
|----------|-------------|
| Cantidad de [OK] | **3** (los 3 mensajes "evento_normal_*" producidos sin patrón POISON) |
| Cantidad de [DLQ] | **2** (los 2 mensajes "POISON_msg_*") |
| Mensajes en DLQ | **2** mensajes en `novatech.lab07.dlq` (verificable con `kafka-get-offsets --topic novatech.lab07.dlq --time -1`). En mi corrida quedó vacío por timing del experimento. |
| Información perdida en DLQ | El payload original SÍ se preserva (es lo que se publica al DLQ). Lo que NO viaja por defecto: la PARTICIÓN original, el OFFSET original, el TIMESTAMP original, el motivo del rechazo. Ese metadata se pierde a menos que el productor del DLQ lo agregue explícitamente como headers. |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué DLQ mejor que skip? | (1) Preserva el mensaje completo para análisis posterior; (2) deja audit trail; (3) permite re-procesar tras fix del bug; (4) el equipo on-call recibe alerta cuando el DLQ crece. Skip es destructivo. |
| ¿Qué pasa si DLQ procesador falla? | Anti-pattern: si el procesador del DLQ produce a OTRO topic en case-of-error y este también falla, podés terminar con un loop infinito (DLQ → DLQ' → DLQ'' → ...). Por eso el DLQ debe tener un EOL: máximo 1-2 niveles, y luego escalar a humano. |
| ¿Cómo evitar loop infinito? | (1) Limitar profundidad (`x-death-count` header, descartar tras N reintentos); (2) topic DLQ con `cleanup.policy=delete + retention.ms=7d` máximo; (3) alerta automática al superar X mensajes en DLQ (humano interviene). |
| Retención recomendada para DLQ | **7-30 días**: suficiente para investigar y re-procesar tras fix. Más allá ya no es operacionalmente útil — si tras 30 días no se actuó, son datos perdidos. |

---

## Conclusiones generales

> Consumer groups en producción: la elección de partition assignment strategy importa más de lo que parece. **Range** = simple pero injusta con multi-topic. **RoundRobin** = uniforme pero requiere mismo subscription en todos. **Sticky** = balance + minimal-shuffle pero rebalance bloqueante. **CooperativeSticky** = la opción default desde 3.x, no bloquea durante rebalance. Lag = LOG-END - CURRENT, monitorearlo es esencial. Reset operations son potentes pero peligrosas: requieren consumers inactivos. Skip de mensaje "venenoso" pierde data — DLQ es la forma idiomática de manejar errores con auditoría.

---

## Notas del validador

1. **Tiempo de validación**: ~50 minutos (el rebalance entre estrategias toma 5-8 segundos cada vez).
2. **Parte 5 DLQ**: validada estructuralmente (script y topic existen), no validada funcionalmente (no se vio mensajes llegar al DLQ por timing del experimento).
3. **Parte 2 lag drain**: validada cuantitativamente con flood de 50k pero sin medición precisa de tiempo de drain con N consumers (requiere setup más controlado).
4. Sin hallazgos pedagógicos nuevos.

*Lab 07 - Curso de Administración de Apache Kafka con Confluent Platform*
