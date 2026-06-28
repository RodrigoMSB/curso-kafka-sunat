# Reporte de Laboratorio 01 — VALIDADO POR MOCITO (referencia instructor)

> **Este archivo NO es el reporte del alumno**. Es la versión completada por el agente de validación, con datos reales obtenidos al ejecutar el lab end-to-end. Sirve de referencia para el instructor.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| **Nombre** | Mocito (validador) |
| **Fecha** | 2026-05-09 |
| **Sección** | N/A (validación instructor) |

---

## Sección 1: Componentes del clúster

| Componente | Imagen Docker | Puerto externo | Rol / Función |
|-----------|--------------|----------------|---------------|
| kafka-broker-1 | confluentinc/cp-kafka:8.2.0 | 9092 | Broker + Controller (KRaft) |
| kafka-broker-2 | confluentinc/cp-kafka:8.2.0 | 9093 | Broker + Controller (KRaft) |
| kafka-broker-3 | confluentinc/cp-kafka:8.2.0 | 9094 | Broker + Controller (KRaft) |
| kafbat-ui | ghcr.io/kafbat/kafka-ui:latest | 8090 (host) → 8080 | UI web para inspección visual del clúster |
| gps-producer | confluentinc/cp-kafka:8.2.0 | (sólo red interna) | Productor de eventos GPS sintéticos al topic `novatech.fleet.gps` |

### Controlador KRaft

| Dato | Valor |
|------|-------|
| Leader ID | 2 |
| Votantes | 3 — broker 1 (CONTROLLER://kafka-broker-1:39092), broker 2 (kafka-broker-2:39093), broker 3 (kafka-broker-3:39094) |
| Epoch actual | 1 |

---

## Sección 2: Distribución de particiones

### Tópico: `novatech.fleet.gps`

| Partición | Broker líder | Réplicas | ISR | ¿Todas sincronizadas? |
|-----------|-------------|----------|-----|----------------------|
| 0 | 3 | 3,1,2 | 3,1,2 | Sí |
| 1 | 1 | 1,2,3 | 1,2,3 | Sí |
| 2 | 2 | 2,3,1 | 2,3,1 | Sí |
| 3 | 1 | 1,3,2 | 1,3,2 | Sí |
| 4 | 3 | 3,2,1 | 3,2,1 | Sí |
| 5 | 2 | 2,1,3 | 2,1,3 | Sí |

### Análisis de distribución

- ¿Los líderes están balanceados entre los brokers? **Sí, distribución 2-2-2** (gracias al cleanup defensivo en `start-lab.sh`).
- ¿Cuántas particiones lidera cada broker?
  - Broker 1: **2** (P1, P3)
  - Broker 2: **2** (P2, P5)
  - Broker 3: **2** (P0, P4)

---

## Sección 3: Tolerancia a fallos

### Estado ANTES de la caída

| Partición | Líder | ISR |
|-----------|-------|-----|
| 0 | 3 | 3,1,2 |
| 1 | 1 | 1,2,3 |
| 2 | 2 | 2,3,1 |
| 3 | 1 | 1,3,2 |
| 4 | 3 | 3,2,1 |
| 5 | 2 | 2,1,3 |

Controlador activo: **2** (LeaderEpoch=1)

### Estado DESPUÉS de la caída (Broker 2 detenido)

| Partición | Líder | ISR |
|-----------|-------|-----|
| 0 | 3 | 3,1 |
| 1 | 1 | 1,3 |
| 2 | 3 | 3,1 |
| 3 | 1 | 1,3 |
| 4 | 3 | 3,1 |
| 5 | 1 | 1,3 |

Controlador activo: **1** (LeaderEpoch=3 — re-elección de controller tras caída)

### Estado DESPUÉS de la recuperación

| Partición | Líder | ISR |
|-----------|-------|-----|
| 0 | 3 | 1,2,3 |
| 1 | 1 | 1,2,3 |
| 2 | 3 | 1,2,3 |
| 3 | 1 | 1,2,3 |
| 4 | 3 | 1,2,3 |
| 5 | 1 | 1,2,3 |

Controlador activo: **1** (LeaderEpoch=3 — el nuevo líder NO devuelve el rol al broker recuperado)

### Observaciones

- ¿El productor GPS siguió funcionando durante la caída? **Sí**, los logs de `gps-producer` muestran eventos #34-#38 publicados durante el período de broker 2 caído (cada 2s sin gap).
- ¿Se perdieron mensajes? **No**, gracias a `min.insync.replicas=2` y RF=3: con 2 brokers vivos seguimos sobre el mínimo, las escrituras se aceptan sin pérdida.
- ¿El broker recuperado volvió a ser líder de alguna partición? **No** (al menos no inmediatamente). P2 y P5 que él lideraba siguen ahora con líderes 3 y 1 respectivamente. Kafka mantiene al nuevo líder elegido — para devolver el liderazgo se necesitaría `kafka-leader-election --election-type preferred` o esperar al `auto.leader.rebalance.interval.ms` (default 5 min).
- Tiempo aproximado de resincronización: **~5-10 segundos** desde que el broker arranca hasta que aparece en ISR de las 6 particiones.

---

## Sección 4: Conclusiones

### ¿Qué aprendí sobre la arquitectura de Kafka?

> Kafka 4.x sin ZooKeeper usa KRaft: los mismos brokers son votantes del quorum de control. El topic `novatech.fleet.gps` con 6 particiones × RF=3 vive distribuido entre los 3 brokers. Cada partición tiene un líder y dos seguidoras (ISR). El productor escribe SOLO al líder; los seguidores tiran (pull) los datos para mantenerse sincronizados.

### ¿Qué aprendí sobre la tolerancia a fallos?

> Con RF=3 y `min.insync.replicas=2`, perder 1 broker no bloquea al cluster: las escrituras siguen aceptándose porque los 2 brokers vivos cumplen el mínimo. El productor GPS no notó la caída. La re-elección de líderes y de controlador es automática y rápida (~5s observado). El cluster pasa de tolerar 2 fallas (RF=3) a tolerar 1 falla (con 1 broker caído quedan 2 réplicas — y `min.insync.replicas=2` ya no permite más caídas sin degradar producción).

### ¿Qué rol juegan las réplicas ISR en la resiliencia del clúster?

> ISR = "in-sync replicas": el subconjunto de réplicas que están al día con el líder. Solo desde ISR se elige al próximo líder (esa es la garantía de no-perder-mensajes). `acks=all` espera confirmación de TODAS las ISR; si una réplica se atrasa demasiado sale del ISR y deja de bloquear escrituras. Cuando el broker caído volvió, sus particiones tuvieron que hacer "catch-up" para reentrar al ISR — durante esos segundos el cluster operaba con ISR reducido a {1,3}.

---

## Sección 5: Desafío extra (opcional)

### Reto 1: Volumen de datos

| Dato | Valor |
|------|-------|
| Bytes totales en `novatech.fleet.gps` | **29.838 bytes** (sumando las 3 réplicas: 9.946 bytes × 3) |
| Comando utilizado | `docker exec kafka-broker-1 kafka-log-dirs --bootstrap-server kafka-broker-1:29092 --describe --topic-list novatech.fleet.gps` |

### Reto 2: Distribución de datos

| Dato | Valor |
|------|-------|
| Partición con más datos | **P0** (29.838 bytes acumulados entre las 3 réplicas) |
| Partición con menos datos | **P1, P2, P3, P4, P5** (TODAS con 0 bytes) |
| Hipótesis de la diferencia | El productor `gps-producer` no especifica clave. Desde Kafka 2.4, el partitioner por defecto es **StickyPartitioner** (no round-robin): se "pega" a una partición hasta que el batch se llena o vence `linger.ms`. Como el productor envía 1 mensaje cada 2 segundos (rate muy bajo), nunca llega a llenar un batch ni a cerrar el linger en otra partición — todos los mensajes terminan en P0. Si el rate fuera de miles de msg/s, sí veríamos distribución entre particiones. |

### Reto 3: Kafbat UI

| Dato | Valor |
|------|-------|
| ¿Cuántos brokers muestra la sección "Brokers"? | **3** (kafka-broker-1, kafka-broker-2, kafka-broker-3) |
| ¿Qué broker aparece marcado como controlador del KRaft? | Tras la recuperación, el controlador es **broker 1** (consistente con el último estado de `check-quorum`). Kafbat muestra `partitionsLeader` por broker — el cluster post-revive tenía 1 con 29 leaders, los otros menos. |
| ¿Cuántas particiones muestra el tópico `novatech.fleet.gps`? | **6** |
| Throughput aproximado (mensajes/segundo) | **~0.5 msg/s** (el productor envía 1 evento cada 2s) |
| ¿Aparece el consumer group `lab01-explorer`? | **Sí**, después de ejecutar `kafka-cli/consume-gps.sh` aparece con offsets por partición. CURRENT-OFFSET=19 en P0, 0 en las demás (consumió 19 mensajes y se desconectó al alcanzar `--max 5` × varias corridas). |
| Screenshot de la vista de mensajes adjunto | N/A (validación instructor — sin screenshots) |

---

## Diagrama

- [ ] N/A (validación instructor — el alumno hace su propio diagrama)

---

## Notas del validador

1. **Cleanup defensivo crítico**: gracias al fix `b096fe1` (en main desde tag `v1.0-pre-curso`), las particiones quedan balanceadas (2-2-2) en una corrida fresca. Sin ese cleanup, todas tendían a quedar con Leader=3 (residuo del lab anterior).
2. **StickyPartitioner es la causa de "P0 tiene todo"**: este lab es un caso ideal para reforzar el concepto que se introduce con más detalle en Lab 02. La guía 02 línea 55 fue corregida en esta fase 2 (`B.1`) para reflejar correctamente el partitioner default.
3. **Tiempo de validación**: ~25 minutos (sin contar StartLab + esperas).

*Laboratorio 01 - Curso de Administración de Apache Kafka con Confluent Platform*
