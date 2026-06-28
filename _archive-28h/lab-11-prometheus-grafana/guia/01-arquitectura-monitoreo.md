# Parte 1: Arquitectura de monitoreo open-source

## Objetivo

Entender cómo se conecta el stack `JMX → JMX Exporter → Prometheus → Grafana`. Verificar que cada pieza está viva y comunicándose.

## Contexto

En el **Lab 08** viste Confluent Control Center (Legacy 7.9.0) que es comercial. En este lab probamos la alternativa **open-source**: Prometheus + Grafana, el stack más usado del mundo para monitoreo (Kubernetes, microservicios, casi todo).

---

## Diagrama

```
[Broker 1] ─┐
[Broker 2] ─┤  JMX (puerto interno 7071, exportado a 7071/7072/7073 host)
[Broker 3] ─┘
   │
   ↓
[JMX Exporter Java agent]  expone /metrics HTTP
   │
   ↓ scrape cada 15s
[Prometheus]  almacena time-series (TSDB)
   │
   ↓ query PromQL
[Grafana]  visualiza dashboards
```

**Diferencia con Lab 08 (CC Next-Gen)**:
- Lab 08: el broker mismo emitía OTLP (cp-server enterprise).
- Lab 11: el broker no se entera de Prometheus. JMX Exporter actúa como bridge entre JMX (estándar Java) y Prometheus.

**Diferencia con Lab 08 (CC Legacy)**:
- Legacy usaba `ConfluentMetricsReporter` que publica a un tópico Kafka.
- Aquí JMX Exporter expone HTTP, Prometheus hace polling.

---

## Actividad 1: Verificar JMX Exporter de los brokers

Cada broker expone métricas en `/metrics` por su puerto JMX Exporter mapeado al host:

```bash
curl -s http://localhost:7071/metrics | head -20
curl -s http://localhost:7072/metrics | head -5
curl -s http://localhost:7073/metrics | head -5
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 3 endpoints responden? | |
| ¿Qué tipos de métricas ves? (counter, gauge, histogram) | |

---

## Actividad 2: Verificar Prometheus

Abre **http://localhost:9090**.

Ir a **Status > Targets**.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos targets aparecen? | |
| ¿Cuántos están UP? | |
| ¿Qué dice la columna "Last Scrape"? | |

> **Pista**: deberías ver 4 targets (1 prometheus + 3 brokers). Todos UP.

---

## Actividad 3: PromQL básico

En **http://localhost:9090** > **Graph**, prueba estas queries:

```promql
# Cuántos brokers están UP
up{job="kafka-brokers"}

# Bytes recibidos por segundo (si hay carga)
rate(kafka_server_brokertopicmetrics_bytesinpersec_total[1m])

# Particiones bajo replicación (debería ser 0 con clúster sano)
kafka_server_replicamanager_underreplicatedpartitions
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿`up` devuelve 1 para los 3 brokers? | |
| ¿Hay datos de bytes? (si hay 0 carga, será 0) | |
| ¿Qué valor tiene `underreplicatedpartitions`? | |

---

## Actividad 4: Verificar Grafana

Abre **http://localhost:3000**.

- Login: `admin` / `admin` (o entra como anónimo, el lab tiene `GF_AUTH_ANONYMOUS_ENABLED=true`)
- Ir a **Dashboards** > Browse
- Debería aparecer un dashboard pre-cargado

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece el dashboard "Kafka Cluster Overview"? | |
| ¿Es navegable sin errores? | |
| ¿Algún panel dice "No data"? | |

> **Pista**: si algún panel dice "No data", es porque la query PromQL del dashboard usa un nombre de métrica que JMX Exporter no genera con esos labels. Es **típico** importar dashboards de la comunidad: hay que ajustarlos. Lo veremos en la guía 02.

---

## Conclusiones

| Concepto | Lo aprendiste explorando... |
|----------|----------------------------|
| JMX Exporter | Java agent que expone métricas como HTTP |
| Prometheus targets | Pull-based scraping cada 15s |
| PromQL | Lenguaje declarativo de métricas |
| Provisioning Grafana | Dashboards pre-cargados desde archivos |

---

## Siguiente paso

Continúa con [Parte 2: Tour por Grafana](02-tour-grafana.md).
