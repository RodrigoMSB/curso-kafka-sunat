# Lab 11 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Arquitectura

| Pregunta | Respuesta esperada |
|----------|-------------------|
| 3 endpoints JMX | Sí, los 3 responden con métricas Prometheus |
| Tipos | counter (acumulados, ej `_total`), gauge (instantáneos, ej `_per_second`), eventualmente histogram |
| Targets totales | 4 (1 prometheus self + 3 brokers) |
| Targets UP | 4 (todos sanos al inicio) |
| Dashboard Grafana | Sí, "Kafka Cluster Overview" pre-cargado |

---

## Parte 2: Tour Grafana

### Métricas iniciales (clúster sin carga)

- Bytes In/Out: ~0 (puede haber tráfico mínimo de tópicos internos)
- Request Rate: bajo, principalmente FetchFollower (replicación interna)
- URP: 0
- Active Controllers: 1 (el primero electo en KRaft)

### Por qué Active Controllers = 1

- 0 → clúster sin liderazgo, NO acepta cambios de metadata (crear tópicos, etc.)
- 2 → "split-brain", catástrofe operacional
- 1 → estado normal: exactamente un controller activo

### Paneles "No data" típicos

El dashboard 11962 puede tener queries para métricas que requieren:
- Otras versiones de Kafka
- JMX Exporter con reglas distintas
- Métricas de ZooKeeper (ya no aplica con KRaft)

Es **típico** y enseñable: dashboards de la comunidad son punto de partida.

---

## Parte 3: Métricas bajo carga

### Con flood 600s @ 200 msg/s

- Bytes In total: ~40 KB/s (200 × 200 bytes)
- Distribución entre brokers: uniforme aproximadamente (sticky partitioner)
- Throughput total: ~200 msg/seg (coincide con producido)

### Tras tumbar broker 2

- Active Controllers: puede pasar de 1 a 0 brevemente y luego volver a 1 (re-elección)
- URP: sube a varios (todas las particiones cuyo follower era broker 2)
- Bytes In/Out broker 2: cae a 0
- Targets UP: baja a 3

### Recuperación

- Broker 2 vuelve UP en ~30s
- URP vuelve a 0 en 30-60s después (catch-up)

---

## Parte 4: Confluent Cloud

| Pregunta | Respuesta |
|----------|-----------|
| ¿Tour o práctico? | Demostrativo (instructor muestra) |
| Crédito gratis | $400 USD por 30 días |
| Tipos cluster | Basic, Standard, Dedicated, Enterprise |
| ¿Por qué no práctico? | Requiere tarjeta de crédito personal; en cursos corporativos genera fricción |
| Latencia | 10-50 ms vs <1ms local |
| Ventajas Cloud | SLA 99.99%, escalabilidad elástica, cero ops |
| Desventajas Cloud | Costo recurrente, latencia de red, datos fuera de tu DC |

---

## Parte 5: Comparativa final

| Caso | Recomendación |
|------|---------------|
| Startup | Kafbat UI + Prometheus/Grafana |
| Empresa 500 personas | CC o Cloud (RBAC + dashboards profesionales) |
| Producción crítica con compliance | CC + Prometheus para detalle técnico |
| ¿Usar varias? | Sí, MUY común. Cada una para su público |
| ¿Por qué no técnica? | Costo, equipo, criticidad, compliance pesan más que features |

---

*Solución - Lab 11*
