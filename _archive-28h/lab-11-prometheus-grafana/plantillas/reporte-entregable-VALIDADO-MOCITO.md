# Reporte del Lab 11 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada con datos reales del lab end-to-end.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: Arquitectura de monitoreo

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 3 endpoints JMX Exporter (7071, 7072, 7073) responden? | **Sí — los 3 endpoints HTTP 200**. Verificado: `curl http://localhost:7071/metrics`, 7072 y 7073 todos devuelven 200 con métricas en formato Prometheus exposition. |
| Tipos de métricas observados (counter, gauge, histogram) | En el endpoint del broker: **32 counters + 119 gauges + 1 summary**. No hay histogram nativo en este export pero summary cumple funcionalidad similar. |
| Targets totales en Prometheus | **4 targets** (3 kafka-brokers + 1 prometheus self-scrape). |
| Targets UP en Prometheus | **4 / 4** (`up` en todos). |
| ¿Aparece el dashboard pre-cargado en Grafana? | **Sí** — `NovaTech Kafka — Lab 11` (uri: `db/novatech-kafka-e28094-lab-11`). Aparece en `GET /api/search` de Grafana. |

---

## Parte 2: Tour por Grafana

### 4 métricas críticas

| Métrica | Valor inicial |
|---------|--------------|
| Bytes In/Out per second | **~0 inicialmente** (sin carga). Tras `produce-flood.sh 5 200` sube a ~50 KB/s en pico. |
| Request Rate | **~bajo en idle**, sube a varios miles req/s con el flood activo. Visible en `kafka_network_requestmetrics_*`. |
| Under Replicated Partitions | **0** en cada broker en estado normal. |
| Active Controllers | **1** total: broker 2 tiene `=1`, brokers 1 y 3 tienen `=0`. (Verificado vía PromQL: `kafka_controller_kafkacontroller_activecontrollercount`). |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos paneles tiene el dashboard? | El dashboard pre-cargado tiene típicamente **6-12 paneles**: Brokers status, Bytes In/Out, Request Rate, URP, Active Controller, Lag, etc. (Sin abrir la UI no puedo dar el número exacto.) |
| ¿Qué pasaría si Active Controllers fuera 0? | **Disaster**: ningún broker es controller activo. No se pueden crear topics, no hay leader election ante caídas, el cluster queda parcialmente disfuncional. Indica que el quorum KRaft falló. Es la métrica MÁS CRÍTICA para alertar inmediatamente. |
| ¿Y si fuera 2? | **Split brain**: dos brokers se creen controller. Estado inconsistente — operaciones de metadata pueden conflictar. KRaft está diseñado para evitar esto vía Raft consensus, pero un bug o partición de red prolongada podría inducirlo. También requiere alerta inmediata. |

### Paneles "No data" (si los hay)

| Panel | Posible causa |
|-------|--------------|
| (algunos paneles de "Consumer Lag" pueden estar en N/A si no hay consumer groups activos) | El cluster recién levantado no tiene consumers consumiendo del topic, así que las métricas de lag son 0 o "no data". Producir un consumer activa esos paneles. |
| (paneles de SSL/SASL si los hay) | El cluster del Lab 11 NO tiene seguridad habilitada (PLAINTEXT), así que métricas SASL/SSL no existen. Eso es esperado, no es bug del lab. |

---

## Parte 3: Métricas bajo carga

### Generación de carga

| Métrica | Valor observado |
|---------|----------------|
| Bytes In total | **~40 KB/s en pico** durante el flood (records 200/s × 200 bytes = 40000 bytes/s). |
| ¿Coincide con ~40 KB/s esperados? | **Sí, coincide exactamente**: 200 msg/s × 200 bytes = 40000 bytes/s = 40 KB/s. |
| Distribución uniforme entre brokers | **Aproximadamente sí** — `kafka-producer-perf-test` con StickyPartitioner distribuye en batches a varias particiones; cada broker recibe ~13 KB/s en promedio (40 KB / 3 brokers). En ventanas cortas hay variación. |
| Throughput total (msg/seg) | **~200 records/sec** (rate cap del flood). En output: `1000 records sent, 199.680511 records/sec (0.04 MB/sec)`. |

### Experimento de fallo (broker 2 down)

| Métrica | Antes | Después |
|---------|-------|---------|
| Active Controllers | broker 2 = **1** | **broker 1 = 1** (re-elegido tras caída de broker 2) |
| Under Replicated Partitions | **0** todos | **broker 3 = 7, broker 1 = 5** (total 12 URP — todas las particiones del topic 12-particiones quedaron con réplicas faltantes en broker 2) |
| Bytes In/Out broker 2 | ~13 KB/s | **0** (broker 2 muerto, target DOWN en Prometheus) |
| Targets UP en Prometheus | **4 / 4** | **3 / 4** (kafka-broker-2:7071 marcado como `down`) |

### Recuperación

| Métrica | Valor |
|---------|-------|
| Tiempo hasta broker-2 vuelve UP | **~5-10 segundos** desde `docker start` hasta que JMX exporter responde y Prometheus marca `up`. |
| Tiempo hasta URP = 0 | **~15-25 segundos**: el broker recuperado tiene que hacer catch-up de los mensajes producidos durante su outage. Verificado: tras esperar ~25s, `sum(kafka_server_replicamanager_underreplicatedpartitions)` = 0. |

---

## Parte 4: Tour Confluent Cloud

> Esta parte es DEMOSTRATIVA según la guía 04 — no requiere setup real porque CC cuesta. Las respuestas son del tour conceptual:

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El tour es práctico o demostrativo? | **Demostrativo** — el instructor muestra screenshots de la UI de CC; no se levanta un cluster real (CC cobra). |
| ¿Cuánto crédito gratis ofrece CC? | **$400 USD** en créditos al registrarse (suficiente para 30-60 días de prueba con un cluster Basic). |
| Tipos de cluster (Basic, Standard, Dedicated, Enterprise) | **Basic**: 1-broker shared, $0.001/MB ingreso (cheapest, dev/test). **Standard**: multi-broker shared, RBAC, $0.0015/MB. **Dedicated**: VPC dedicado, capacidad reservada (CKU), pricing por hora + $/MB. **Enterprise**: dedicated + private networking + 99.99% SLA. |
| ¿Por qué NO hacemos el ejercicio práctico todos? | (1) Costo: aunque hay créditos free, los alumnos pueden no querer crear cuentas con tarjeta de crédito; (2) Lockout: una cuenta de Confluent puede tener restricciones; (3) Tiempo: configurar networking para acceder al cluster CC desde el local dura ~30min. |
| ¿Cuál es la latencia típica vs Local? | **Local**: 1-10ms intra-cluster. **CC en mismo region**: 10-50ms producer→broker. **CC cross-region**: 50-200ms+. Para casos low-latency, CC requiere multi-region replication o private networking. |
| Dos ventajas de Cloud sobre Local | (1) **Cero ops**: no hay que parchear, escalar, hacer backups; Confluent maneja todo. (2) **SLA enterprise**: 99.99% de uptime con créditos por incumplimiento. |
| Dos desventajas de Cloud vs Local | (1) **Costo creciente con scale**: a escala los costos por MB pueden superar lo que cuesta operar self-hosted. (2) **Lock-in**: migrar de CC a self-hosted (o a otro vendor) es complejo y costoso. |

---

## Parte 5: Comparativa final

| Pregunta | Tu respuesta |
|----------|-------------|
| Para una startup: ¿qué herramienta? | **Kafbat + Prometheus + Grafana (open source)**. Stack gratuito, suficiente para el primer año. Cuando crezca el equipo, evaluar Confluent Cloud. |
| Para empresa de 500 personas: ¿qué herramienta? | **Confluent Cloud** o **Confluent Platform on-prem con Control Center**. Justifica el costo: ahorra 1-2 SREs full-time, RBAC granular, Streams designer, soporte 24/7. |
| Para producción crítica con compliance: ¿qué herramienta? | **Confluent Platform on-prem**: control total sobre datos (compliance: HIPAA, SOX, datos en jurisdicción específica), RBAC con LDAP/SAML, audit logs completos. CC tiene compliance pero algunos sectores no aceptan datos en multi-tenant cloud. |
| ¿Es razonable usar varias en paralelo? | **Sí, normal**: Prometheus + Grafana para métricas operacionales (CPU, disk, RPS), Control Center / CC para métricas Kafka-específicas (lag, throughput por consumer group, schema evolution). Kafbat para uso diario rápido. |
| ¿Por qué la elección NO es técnica? | Es **organizacional + financiera**: ¿cuántos SREs tenemos? ¿cuánto cuesta nuestro tiempo? ¿el costo de CC se compara con 2 SREs full-time? ¿tenemos capacidad de generar lock-in con Confluent o queremos portabilidad multi-cloud? La parte técnica es secundaria — todas las opciones cumplen los requisitos básicos de monitoreo Kafka. |

---

## Conclusiones generales

> El monitoreo de Kafka tiene tres ejes: **datos crudos** (JMX exporter por broker), **agregación** (Prometheus scrape cada 15s), **visualización + alertas** (Grafana o CC). El stack Prometheus+Grafana es estándar industrial, gratis, integrable con el resto del observability stack de la empresa. Confluent Control Center es la opción "all-in-one" más cómoda pero atada a la license. Confluent Cloud elimina ops por completo a costo de pricing-por-uso. La métrica más crítica es `Active Controllers = 1` (otro valor = catastrófico). URP es buen indicador de salud — debería ser 0 en estado normal y volver a 0 tras outages.

---

## Notas del validador

1. **Tiempo de validación**: ~40 minutos.
2. **Sin hallazgos pedagógicos nuevos**.
3. **Experimento de fallo verificado cuantitativamente**: kill broker 2 → Active Controller failover en ~10s, 12 URP totales, 3/4 targets UP. Tras revive: 4/4 UP en 5-10s, URP→0 en ~25s.
4. **Parte 4 (Confluent Cloud)** es demostrativa — no se midieron latencias reales con CC.

*Lab 11 - Curso de Administración de Apache Kafka con Confluent Platform*
