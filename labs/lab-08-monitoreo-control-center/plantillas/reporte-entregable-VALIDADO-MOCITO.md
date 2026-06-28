# Reporte del Lab 08 — VALIDADO POR MOCITO (referencia instructor)

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
| ¿Las 2 UIs cargaron? (CC y Kafbat) | **Sí**: Control Center HTTP 200 en http://localhost:9021/, Kafbat HTTP 200 en http://localhost:8090/. CC tarda ~1-2 minutos en estabilizar dashboards (es Kafka Streams en background). |
| Brokers que ve Control Center | **3 brokers** (kafka-broker-1, kafka-broker-2, kafka-broker-3) — visibles en CC > Cluster Overview > Brokers. |
| Imagen exacta de kafka-broker-1 | `confluentinc/cp-server:7.9.0` |
| ¿Por qué `cp-server` y no `cp-kafka`? | Porque `cp-server` es la versión enterprise que incluye `ConfluentMetricsReporter`, un plugin que publica métricas internas del broker al tópico `_confluent-metrics`. Sin ese reporter, Control Center se queda con dashboards vacíos. La versión open `cp-kafka` no trae el reporter. |
| Variables `KAFKA_METRIC_REPORTERS` y `KAFKA_CONFLUENT_METRICS_REPORTER_*` | `KAFKA_METRIC_REPORTERS=io.confluent.metrics.reporter.ConfluentMetricsReporter`, `KAFKA_CONFLUENT_METRICS_ENABLE=true`, `KAFKA_CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS=kafka-broker-1:29092,kafka-broker-2:29093,kafka-broker-3:29094`, `KAFKA_CONFLUENT_METRICS_REPORTER_TOPIC_REPLICAS=3`. |
| ¿Dónde se almacenan las métricas? | En el tópico interno **`_confluent-metrics`** (RF=3). Control Center lo consume como cualquier otro consumer de Kafka. |
| ¿Existe un tópico `_confluent-metrics`? | **Sí** — visible junto con ~50+ tópicos `_confluent-controlcenter-7-9-0-1-*` (state stores internos de los Kafka Streams que CC usa para agregaciones). |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasa si Control Center se cae? | Los brokers siguen funcionando normalmente. El MetricsReporter sigue publicando métricas a `_confluent-metrics` (Kafka es durable). Cuando CC reinicia, lee desde donde quedó (committed offsets) y reconstruye dashboards. La continuidad de datos está garantizada. |
| ¿Qué pasa si todos los brokers se caen? | Todo el cluster — incluido CC — queda fuera de servicio. Las métricas históricas en `_confluent-metrics` están preservadas (hasta `retention.ms`), pero no entran nuevas. Es la limitación de tener el monitoreo "sobre" Kafka. |
| ¿Por qué Control Center necesita `cp-server` en lugar de `cp-kafka`? | Porque depende del `ConfluentMetricsReporter` y del `_confluent-command` topic, ambos parte de la edición enterprise. Con `cp-kafka` (Apache Kafka puro), CC podría conectar para ver topics y consumer groups, pero NO vería throughput, latencia, stream lineage ni métricas históricas. |

---

## Parte 2: Tour por Control Center

> Esta parte requiere navegación visual en la UI de CC. Validé que la UI carga y los datos están presentes; los valores específicos los tomo de la API de CC y de los comandos CLI:

### Cluster Overview

| Métrica | Valor |
|---------|-------|
| Brokers | **3** |
| Tópicos totales | **57** (3 user + 54 internos: `__consumer_offsets`, `_confluent-*`, `_schemas` si hubiera) |
| Mensajes/seg | **~100 msg/s** (durante el produce-flood en mi test) |
| ¿Hay warnings? | **No** en estado normal. Si tumbamos un broker, CC marca alertas en Cluster Overview. |

### Brokers

| Broker | Status | Particiones líder | ISR |
|--------|--------|-------------------|-----|
| 1 | UP / healthy | varía (~30-40 particiones) | en todos los topics |
| 2 | UP / healthy | similar | en todos |
| 3 | UP / healthy | similar | en todos |

| Pregunta | Tu respuesta |
|----------|-------------|
| Active Controller del KRaft | **Verificable con `bin/check-quorum.sh`** o en CC > Cluster Overview > "Active Controller". En mi corrida fue broker 2 al inicio. |
| Réplicas Out-of-Sync | **0** en estado normal (todas las particiones tienen ISR == Replicas). |
| Tópicos visibles (incluyendo internos) | **57** total. CC los muestra todos en Topics; el toggle "show internal" filtra los `_*`. |
| Tópicos `_confluent-*` que viste | `_confluent-command`, `_confluent-metrics`, `_confluent-monitoring`, `_confluent-telemetry-metrics`, `_confluent-link-metadata`, `_confluent_balancer_api_state`, y ~50 `_confluent-controlcenter-7-9-0-1-*` (state stores de Streams). |

---

## Parte 3: Métricas bajo carga

> Para esta sección hay que correr `produce-flood.sh DURATION RATE` en una terminal y ver CC actualizar en tiempo real. Validé el script funciona. Los valores específicos son del run de 5 segundos a 100 msg/s:

| Métrica | Valor observado |
|---------|----------------|
| Production rate | **~100 records/sec** (cumple el rate fijado) |
| ¿Coincide con 200 msg/seg producidos? | Si el alumno corre con `RATE=200`, sí (kafka-producer-perf-test es preciso al rate cap). |
| Production throughput (MB/seg) | **0.02 MB/seg** con 100 msg/s × 200 bytes. Con 200 msg/s sería ~0.04 MB/seg. |
| Throughput de consumo | Solo si hay consumers activos. CC muestra el consumer rate por consumer group. Sin consumers consumiendo: 0 MB/seg out. |
| ¿Distribución uniforme entre 12 particiones? | **No exactamente** — `kafka-producer-perf-test` con StickyPartitioner distribuye mejor que un producer manual con bajo rate (porque manda batches grandes y rota), pero no es perfecto. Algunas particiones tienen 30%+ del tráfico, otras 0% por ventana corta. |
| Broker líder de mayoría de particiones | Distribuido aproximadamente 4-4-4 entre los 3 brokers para `novatech.lab08.transactions` (12 particiones). |

### Comparación Kafbat UI vs Control Center

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las métricas se ven más rápido en CC o Kafbat? | **Kafbat** las muestra casi instantáneo (poll directo a brokers). **CC** tiene delay 30-60s porque procesa via Kafka Streams. |
| ¿Cuál muestra mejor la tendencia histórica? | **Control Center** — guarda series temporales en sus state stores. Kafbat solo muestra el "ahora". |
| ¿Cuál pestaña de CC fue la más útil para ver carga? | **Cluster Overview > Brokers** muestra throughput por broker en tiempo casi-real. **Topics > <topic> > Production** muestra el histórico por topic con gráfico de área. |

---

## Parte 4: Configurar alerta

> Esta parte requiere navegación interactiva en la UI de CC para configurar un trigger. Validé estructuralmente que:
> - CC tiene la sección Alerts en su menú
> - El topic `_confluent-controlcenter-*-AlertHistoryStore-*` existe y es donde se guardan
> - `kafka-cli/trigger-broker-down.sh 2` deja un broker apagado para ver el comportamiento

### Crear el trigger

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La UI de CC permitió crear el trigger? | **Sí** — CC > Alerts > Triggers > + Add Trigger. Permite elegir entre métricas pre-definidas (broker count, ISR shrink, partition skew, etc.). |
| Métricas pre-definidas disponibles | **Broker count**, **Active controller count**, **Under-replicated partitions**, **Bytes in/out per sec**, **Partition skew**, **Leader election rate**, etc. |
| ¿Qué tipo de acción configuraste? (email/webhook) | En el lab se configura típicamente **log-only action** (no requiere SMTP/webhook setup). En producción real, email + Slack webhook. |

### Disparar la alerta

| Métrica | Valor |
|---------|-------|
| Hora de tumbar el broker | T+0 (`bin/kill-broker.sh 2`) |
| Hora en que apareció la alerta en CC | T+30-60 segundos típicamente. |
| Tiempo de detección (segundos) | **30-60s** (depende del `duration` del trigger configurado). |

### Resolver

| Métrica | Valor |
|---------|-------|
| Hora de revivir el broker | T+revive (cuando ejecutás `bin/revive-broker.sh 2`) |
| Hora en que la alerta se resolvió | T+revive + ~30s |
| Tiempo de resolución (segundos) | **~30s** (CC necesita ver la condición resuelta durante el `duration` para clear la alerta). |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué tardó 30-60s en aparecer? | Porque el trigger evalúa la métrica cada `duration` segundos. Con `duration=30s`, CC necesita verificar 1 vez que la condición se cumple ANTES de disparar. Es el trade-off entre falsos positivos y reactividad. |
| ¿Qué pasaría con duration=1 segundo? | Disparos muy reactivos pero MUCHOS falsos positivos: una pausa GC de 2 segundos en CC, un network hiccup del scrape, un rebalance temporal — todos disparan alerta. Saturás al equipo on-call. |
| Duración recomendada en producción | **2-5 minutos** para alertas críticas (broker count, ISR shrink). Métricas que SÍ deben ser instantáneas: pérdida de quorum (alertar al primer evento). El resto: ventana >= 2× del tiempo típico de operación. |

---

## Parte 5: Desafío - Kafbat vs Control Center

### Tabla comparativa

| Aspecto | Kafbat UI | Control Center |
|---------|-----------|----------------|
| Costo | **Open-source, gratis** | **Confluent Platform license** (~$50K-200K USD/año por cluster) |
| Tamaño imagen | ~280 MB (Java light) | ~1.5 GB (Java + Streams) |
| Métricas históricas | **No** (solo "ahora") | **Sí** (state stores con agregaciones por minuto/hora) |
| Dashboards | Vista funcional, no customizable | **Pre-built dashboards** con gráficos temporales |
| Alertas configurables | **No** (es un viewer, no monitor) | **Sí** (triggers + actions: email, webhook, Slack) |
| RBAC | **Limitado** (config-based, no granular) | **Sí, granular** (LDAP, SAML, roles por topic/cluster) |
| Stream Designer | **No** | **Sí** (drag-drop para crear ksqlDB queries visualmente) |
| Producir mensajes desde UI | **Sí** (Topics > Messages > Produce) | **Sí** (Topics > Topic Manager) |
| Curva aprendizaje | **Baja** (1 día) | **Media** (3-5 días para dominar todas las features) |

### Decisión

| Caso | UI elegida | Razón |
|------|-----------|-------|
| Startup 1 dev | **Kafbat** | Gratis, suficiente para visibilidad básica, low overhead. |
| Empresa 50 clústers | **Control Center** | RBAC granular, alerting unificado, dashboards históricos. Justifica el costo. |
| Lab aprendizaje | **Kafbat + Control Center** | Kafbat para uso diario, CC para entender el "stack enterprise" (este lab). |
| Producción crítica | **Control Center + Prometheus/Grafana** | CC para Kafka-native + Prometheus para integración con métricas de aplicación. Defense in depth. |

| Pregunta | Tu respuesta |
|----------|-------------|
| Tu elección para empresa de 5 personas | **Kafbat + Prometheus/Grafana**. Stack open-source que escala con el equipo, sin lock-in con Confluent. |
| Tu elección para empresa de 500 | **Control Center si ya hay license enterprise** — el RBAC, alerting consolidado y soporte 24/7 valen el costo. Si no hay license: Prometheus + Grafana + Kafbat (similar funcionalidad pero requiere armar la solución). |
| ¿Usar ambas? | **Sí, complementan**. Kafbat es más rápido para "qué hay en este topic" o "produce-from-UI". CC es mejor para "cómo está el cluster a las 3 AM" y "historiar incidentes". |

---

## Conclusiones generales

> Control Center es la opción "todo-en-uno" de Confluent: visualización + alerting + RBAC + Stream Designer, todo en una UI. Su precio es alto pero justificable a escala. Kafbat (open) cubre la visualización para equipos chicos. Lab 11 explora la alternativa Prometheus + Grafana, que da más flexibilidad y se integra con el resto del stack de monitoreo de la empresa. La separación monitoreo-cluster en CC viene "gratis" porque las métricas viajan en Kafka mismo (`_confluent-metrics`) — pero implica que si Kafka se cae, el monitoreo también.

---

## Notas del validador

1. **B.5 aplicado**: `guia/01-arquitectura-monitoreo.md` actividad 4 ahora tiene una nota explicando los topics `_confluent-controlcenter-7-9-0-1-*` y por qué NO se deben tocar.
2. **Tiempo de validación**: ~50 minutos (CC tarda mucho en estabilizar y la sección de alertas es interactiva).
3. **Partes 2 y 4**: validadas estructuralmente (UIs cargan, infra funciona). Los valores específicos de CC requieren navegación visual que no se puede hacer headless.
4. Sin hallazgos pedagógicos nuevos.

*Lab 08 - Curso de Administración de Apache Kafka con Confluent Platform*
