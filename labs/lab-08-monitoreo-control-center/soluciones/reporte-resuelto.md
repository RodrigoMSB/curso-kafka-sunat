# Lab 08 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Arquitectura

### Respuestas esperadas

| Pregunta | Respuesta esperada |
|----------|-------------------|
| 2 UIs cargaron | Sí (Control Center 9021, Kafbat 8090) |
| Brokers que ve CC | 3 |
| Imagen kafka-broker-1 | `confluentinc/cp-server:7.9.0` |
| ¿Por qué cp-server? | Es la versión enterprise que incluye `ConfluentMetricsReporter`. Sin esto, CC no recibiría métricas y mostraría dashboards vacíos |
| Variables clave | `KAFKA_METRIC_REPORTERS=io.confluent.metrics.reporter.ConfluentMetricsReporter` y `KAFKA_CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS` |
| Dónde se almacenan las métricas | En el tópico interno `_confluent-metrics` del propio clúster Kafka |
| ¿Existe `_confluent-metrics`? | Sí, se crea automáticamente al arrancar los brokers |

### Reflexión

- **CC caído**: los brokers siguen normalmente. Las métricas se siguen acumulando en `_confluent-metrics`. Cuando CC vuelva, recupera el histórico desde el tópico (con la retención configurada).
- **Brokers caídos**: CC pierde la fuente de métricas. Pero los datos previos quedan en el tópico hasta que se purguen por retención.
- **`cp-server` vs `cp-kafka`**: solo `cp-server` viene con `ConfluentMetricsReporter` empaquetado. `cp-kafka` es la versión open-source pura sin extensiones enterprise.

---

## Parte 2: Tour Control Center

### Métricas típicas

- **Brokers**: 3 (todos UP)
- **Tópicos**: ~10-15 (usuario + internos `_confluent-*`, `__consumer_offsets`)
- **Mensajes/seg**: depende de carga; con productor GPS solo, ~0.5 msg/seg

### Distribución de líderes

Con 3 brokers y RF=3, las particiones se distribuyen uniformemente. Para `novatech.lab08.transactions` (12 particiones), cada broker debería ser líder de 4.

### Active Controller

Varía: cualquiera de los 3 (el primero electo en KRaft). Generalmente el broker-1 al ser el primero en arrancar.

### Tópicos `_confluent-*` esperados

- `_confluent-metrics`: las métricas que CC consume
- `_confluent-controlcenter-*`: tópicos internos de CC para su estado
- `_confluent-monitoring`: monitoreo de interceptors (si aplica)
- `_confluent-license`: gestión de licencia

---

## Parte 3: Métricas bajo carga

### Métricas típicas con `produce-flood.sh 600 200`

- **Production rate**: ~200 msg/seg (puede aparecer ligeramente menor por agregación)
- **Throughput**: ~40 KB/seg (200 msg × 200 bytes)
- **Consumo**: depende; los consumers internos de CC consumen tópicos `_confluent-*`

### Distribución entre particiones

Esperado: las 12 particiones reciben mensajes de manera relativamente uniforme (sticky partitioner del producer-perf-test).

### Comparación Kafbat vs CC

- **Kafbat**: vista en tiempo real instantánea, pero sin histórico.
- **CC**: dashboards con tendencia histórica desde que CC arrancó (lee de `_confluent-metrics` que tiene retención).

Diferencia clave: **CC permite ver "qué pasó hace 1 hora", Kafbat solo "qué pasa AHORA"**.

---

## Parte 4: Alerta

### Tiempos típicos

- **Detección**: 30-90 segundos después de tumbar el broker
- **Resolución**: 30-90 segundos después de revivir el broker

### Por qué duraciones

- **30s no es instantáneo**: el `ConfluentMetricsReporter` publica al tópico cada 60s por default; CC lee y evalúa la regla.
- **Duration=1s**: causaría flapping. Cualquier blip momentáneo dispararía la alerta.
- **Producción**: típicamente 5 min para alertas no críticas, 30s-2min para críticas.

### Verificación

- **CC > Alerts**: alerta activa en rojo en la página de alertas
- **CC > Brokers**: el broker tumbado aparece como down
- **CC > Topics**: tópicos con réplicas faltantes muestran warnings

---

## Parte 5: Desafío

### Tabla comparativa esperada

| Aspecto | Kafbat UI | Control Center |
|---------|-----------|----------------|
| Costo | Gratis (Apache 2.0) | Comercial (eval gratis) |
| Tamaño imagen | ~200 MB | ~1.5 GB |
| Métricas históricas | No | Sí (vía `_confluent-metrics`) |
| Dashboards | Básicos | Profesionales |
| Alertas configurables | No | Sí (nativas en CC) |
| RBAC | No (en open source) | Sí |
| Stream Designer | No | Sí |
| Producir mensajes desde UI | Sí | Sí |
| Curva aprendizaje | Baja | Media-alta |

### Decisión por caso

- **Startup 1 dev**: Kafbat. Suficiente, gratis, rápido.
- **Empresa 50 clústers**: CC. Necesitas RBAC, alertas, dashboards profesionales.
- **Lab aprendizaje**: Kafbat. Más simple para empezar.
- **Producción crítica**: CC. Alertas son no-negociables.
- **Investigación rápida**: Kafbat. Más ágil.
- **Reporte ejecutivo**: CC. Dashboards "presentables".

### Conclusión esperada

**Muchas empresas usan AMBAS**: Kafbat para devs y CC para NOC/operaciones. No es excluyente.

---

*Solución - Lab 08*
