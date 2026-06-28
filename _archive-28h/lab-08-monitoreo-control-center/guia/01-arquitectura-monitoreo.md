# Parte 1: Arquitectura de monitoreo

## Objetivo

Entender la arquitectura de monitoreo de un clúster Kafka enterprise con Confluent Control Center Legacy. Diferenciar `cp-kafka` (open) de `cp-server` (enterprise) y verificar que cada componente está vivo.

## Contexto

Hasta el Lab 07 viste el clúster con Kafbat UI: una sola interfaz que se conecta directo a los brokers. Eso funciona para básicos. Pero en producción real necesitas:
- **Métricas históricas** (no solo "ahora")
- **Alertas automáticas** (no esperar que alguien mire la UI)
- **Dashboards profesionales** (que se puedan mostrar al directorio)

La solución de Confluent: **ConfluentMetricsReporter + tópico interno + Control Center**.

---

## Diagrama de arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                  Plano de monitoreo (Legacy 7.9.0)                   │
│                                                                      │
│   [Broker 1] ┐                                                       │
│   [Broker 2] ├──→ [Tópico _confluent-metrics] ←── [Control Center]   │
│   [Broker 3] ┘    (interno de Kafka)                                 │
│                                                                      │
│                       Kafka data plane (separado)                    │
│   [Productor GPS] ──→ [Brokers] ←── [Kafbat UI / Consumers]          │
└─────────────────────────────────────────────────────────────────────┘
```

**Clave**: el plano de **monitoreo** comparte la infraestructura de Kafka. Las métricas viajan como mensajes en un tópico INTERNO (`_confluent-metrics`). Control Center las consume como cualquier otro consumer.

---

## Actividad 1: Verificar cada componente

Abre las 2 UIs en tabs distintos del navegador:

| URL | Servicio | Qué verificar |
|-----|----------|---------------|
| http://localhost:9021 | Control Center | Dashboard "Cluster Overview" |
| http://localhost:8090 | Kafbat UI | Lista de brokers y tópicos |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 2 UIs cargaron? | |
| ¿Cuántos brokers ve Control Center? | |
| ¿Aparece el tópico `_confluent-metrics` en Kafbat UI (incluyendo internos)? | |

---

## Actividad 2: Confirmar que es `cp-server`, no `cp-kafka`

```bash
docker inspect kafka-broker-1 --format '{{.Config.Image}}'
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál es la imagen exacta? | |
| ¿Por qué este lab usa `cp-server` y no `cp-kafka`? | |

> **Pista**: `cp-server` es la versión enterprise. Trae `ConfluentMetricsReporter` que publica métricas al tópico `_confluent-metrics` automáticamente. Sin esto, Control Center se queda con dashboards vacíos.

---

## Actividad 3: Inspeccionar el MetricsReporter

```bash
docker inspect kafka-broker-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E 'METRIC|CONFLUENT_METRICS'
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué clase reporta métricas? (`KAFKA_METRIC_REPORTERS`) | |
| ¿A qué bootstrap-servers publica? | |
| ¿Cuántas réplicas tiene el tópico de métricas? | |

---

## Actividad 4: Verificar que el tópico de métricas existe y tiene mensajes

```bash
# El tópico interno
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --list | grep _confluent
```

> **Nota:** Al levantar Control Center vas a ver una serie de tópicos nuevos con prefijo `_confluent-controlcenter-7-9-0-1-*` (alrededor de 50 tópicos). Estos los crea Control Center automáticamente para guardar su estado interno: configuración de alertas, métricas históricas agregadas, dashboards persistidos, store de Kafka Streams para procesar las métricas. **NO los modifiques ni los borres**: si los borrás, Control Center pierde toda su configuración y dashboards y hay que reiniciar el lab desde cero. Pensalos como las "tablas internas" de Control Center, equivalentes a las tablas de sistema de un RDBMS. El tópico que importa para vos en esta actividad es `_confluent-metrics` (donde el MetricsReporter de cada broker publica las métricas crudas).

```bash
# Una muestra de un mensaje (sale binario; ver solo el primer evento)
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic _confluent-metrics \
    --from-beginning --max-messages 1 --timeout-ms 5000 2>&1 | head -5
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Existe `_confluent-metrics`? | |
| ¿Tiene mensajes? | |
| ¿Por qué los mensajes son binarios (no texto plano)? | |

> **Pista**: las métricas se serializan en formato binario (Avro/Protobuf) por eficiencia. Control Center sabe deserializarlas; nosotros normalmente no las leemos directo.

---

## Actividad 5: Reflexión sobre la arquitectura

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasaría si Control Center se cae? | |
| ¿Qué pasaría si los brokers se caen? | |
| ¿Por qué guardar métricas en Kafka mismo es elegante? | |

> **Pista respuestas**: Sin CC, brokers siguen, métricas se acumulan en `_confluent-metrics`, al volver CC consume desde donde quedó. Brokers caídos = todo se cae. Usar Kafka como backbone de telemetría aprovecha la durabilidad y replicación que ya tenés.

---

## Conclusiones

| Concepto | Lo aprendiste explorando... |
|----------|----------------------------|
| `cp-server` vs `cp-kafka` | Edition enterprise con MetricsReporter |
| `_confluent-metrics` | Tópico interno donde viajan métricas |
| Separación de planos | Monitoreo viaja sobre Kafka mismo |
| Stack simple | Solo CC, sin Prometheus/Alertmanager externos |

---

## Siguiente paso

Continúa con [Parte 2: Tour por Control Center](02-tour-control-center.md).
