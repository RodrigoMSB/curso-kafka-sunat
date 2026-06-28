# Parte 3: Métricas bajo carga

## Objetivo

Generar carga real sostenida y observar cómo Grafana refleja el estado del clúster en tiempo real. Después, simular un fallo (broker caído) y ver cómo lo detectan los dashboards.

## Contexto

Las métricas en un clúster ocioso son aburridas. Necesitamos carga para ver throughput, latencia, replicación, y experimentar con fallos.

---

## Actividad 1: Generar carga sostenida

En **terminal A**:

```bash
kafka-cli/produce-flood.sh 600 200
```

Produce 200 msg/seg durante 600 segundos (10 min) al tópico `novatech.lab11.eventos`.

**Mantén el comando corriendo.** Abre Grafana en otra ventana.

---

## Actividad 2: Observar throughput en Grafana

En el dashboard "Kafka Cluster Overview":

| Métrica | Valor observado |
|---------|----------------|
| Bytes In per second (total) | |
| ¿Coincide con ~40 KB/s (200 msg × 200 bytes)? | |
| Distribución entre brokers (¿uniforme?) | |
| Bytes Out per second | |

> **Pista**: Bytes Out puede ser mayor que Bytes In si hay réplicas (cada mensaje se envía a 2 followers además del líder).

---

## Actividad 3: Métricas en Prometheus directamente

En **http://localhost:9090** > Graph:

```promql
# Throughput total del clúster
sum(rate(kafka_server_brokertopicmetrics_bytesinpersec_total[1m]))

# Throughput por broker
sum by (instance) (rate(kafka_server_brokertopicmetrics_bytesinpersec_total[1m]))

# Total de mensajes por segundo
sum(rate(kafka_server_brokertopicmetrics_messagesinpersec_total[1m]))
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Throughput total (msg/seg) | |
| ¿Coincide con los 200 msg/seg producidos? | |

---

## Actividad 4: Experimento de fallo

Sin detener el flood, abre otra terminal y tumba el broker 2:

```bash
kafka-cli/trigger-broker-down.sh 2
```

**Mira el reloj**: en 30-60 segundos deberías ver en Grafana:

| Métrica | Antes | Después |
|---------|-------|---------|
| Active Controllers | 1 | |
| Under Replicated Partitions | 0 | |
| Bytes In/Out de broker 2 | ~13 KB/s | |
| Targets UP en Prometheus | 4 | |

---

## Actividad 5: Verificar en Prometheus

En **http://localhost:9090** > Status > Targets:

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos targets están DOWN? | |
| ¿Qué error muestra? | |

---

## Actividad 6: Revivir el broker

```bash
docker compose -f infra/docker-compose.yml --env-file infra/.env up -d kafka-broker-2
```

Espera 30-60 segundos. Observa en Grafana:

| Métrica | Valor |
|---------|-------|
| Tiempo hasta que broker-2 vuelve UP | |
| Tiempo hasta URP = 0 | |
| ¿Bytes In/Out de broker-2 vuelve a aparecer? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál métrica te avisaría primero de un problema serio? | |
| ¿Por qué Prometheus tarda 15s en detectar que el broker cayó? | |
| ¿Qué diferencia hay con CC Legacy del Lab 08? | |

> **Pista**: el `scrape_interval=15s` define cuánto tarda en detectar. Bajarlo a 5s acelera la detección pero genera más carga. CC Legacy usaba un tópico Kafka como bus de métricas; aquí Prometheus hace polling HTTP.

---

## Conclusiones

| Concepto | Lo aprendiste viendo... |
|----------|------------------------|
| Throughput en vivo | Carga sostenida + dashboards |
| Detección de fallos | URP > 0 cuando un broker muere |
| Recuperación | Catch-up automático tras revivir |
| Latencia detección | Definida por `scrape_interval` |

---

## Cierre

Detén el flood (Ctrl+C en terminal A) cuando termines.

---

## Siguiente paso

Continúa con [Parte 4: Tour por Confluent Cloud](04-confluent-cloud-tour.md).
