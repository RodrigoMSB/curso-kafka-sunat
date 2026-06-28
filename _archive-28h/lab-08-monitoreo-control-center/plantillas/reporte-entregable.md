# Reporte del Lab 08: Monitoreo profesional con Control Center

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Arquitectura de monitoreo

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 2 UIs cargaron? (CC y Kafbat) | |
| Brokers que ve Control Center | |
| Imagen exacta de kafka-broker-1 | |
| ¿Por qué `cp-server` y no `cp-kafka`? | |
| Variables `KAFKA_METRIC_REPORTERS` y `KAFKA_CONFLUENT_METRICS_REPORTER_*` | |
| ¿Dónde se almacenan las métricas? | |
| ¿Existe un tópico `_confluent-metrics`? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasa si Control Center se cae? | |
| ¿Qué pasa si todos los brokers se caen? | |
| ¿Por qué Control Center necesita `cp-server` en lugar de `cp-kafka`? | |

---

## Parte 2: Tour por Control Center

### Cluster Overview

| Métrica | Valor |
|---------|-------|
| Brokers | |
| Tópicos totales | |
| Mensajes/seg | |
| ¿Hay warnings? | |

### Brokers

| Broker | Status | Particiones líder | ISR |
|--------|--------|-------------------|-----|
| 1 | | | |
| 2 | | | |
| 3 | | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| Active Controller del KRaft | |
| Réplicas Out-of-Sync | |
| Tópicos visibles (incluyendo internos) | |
| Tópicos `_confluent-*` que viste | |

---

## Parte 3: Métricas bajo carga

| Métrica | Valor observado |
|---------|----------------|
| Production rate | |
| ¿Coincide con 200 msg/seg producidos? | |
| Production throughput (MB/seg) | |
| Throughput de consumo | |
| ¿Distribución uniforme entre 12 particiones? | |
| Broker líder de mayoría de particiones | |

### Comparación Kafbat UI vs Control Center

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las métricas se ven más rápido en CC o Kafbat? | |
| ¿Cuál muestra mejor la tendencia histórica? | |
| ¿Cuál pestaña de CC fue la más útil para ver carga? | |

---

## Parte 4: Configurar alerta

### Crear el trigger

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La UI de CC permitió crear el trigger? | |
| Métricas pre-definidas disponibles | |
| ¿Qué tipo de acción configuraste? (email/webhook) | |

### Disparar la alerta

| Métrica | Valor |
|---------|-------|
| Hora de tumbar el broker | |
| Hora en que apareció la alerta en CC | |
| Tiempo de detección (segundos) | |

### Resolver

| Métrica | Valor |
|---------|-------|
| Hora de revivir el broker | |
| Hora en que la alerta se resolvió | |
| Tiempo de resolución (segundos) | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué tardó 30-60s en aparecer? | |
| ¿Qué pasaría con duration=1 segundo? | |
| Duración recomendada en producción | |

---

## Parte 5: Desafío - Kafbat vs Control Center

### Tabla comparativa

| Aspecto | Kafbat UI | Control Center |
|---------|-----------|----------------|
| Costo | | |
| Tamaño imagen | | |
| Métricas históricas | | |
| Dashboards | | |
| Alertas configurables | | |
| RBAC | | |
| Stream Designer | | |
| Producir mensajes desde UI | | |
| Curva aprendizaje | | |

### Decisión

| Caso | UI elegida | Razón |
|------|-----------|-------|
| Startup 1 dev | | |
| Empresa 50 clústers | | |
| Lab aprendizaje | | |
| Producción crítica | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| Tu elección para empresa de 5 personas | |
| Tu elección para empresa de 500 | |
| ¿Usar ambas? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre monitoreo profesional:

```



```

---

*Lab 08 - Curso de Administración de Apache Kafka con Confluent Platform*
