# Guía 05 — Comparativa final: 3 enfoques de monitoreo Kafka

| Aspecto | Kafbat UI | Prometheus + Grafana | Confluent Control Center | Confluent Cloud |
|---------|-----------|----------------------|--------------------------|-----------------|
| Lab donde lo viste | 01-10 | **11 (este)** | 08 | 11 (tour) |
| Costo licencia | Gratis | Gratis | Comercial (eval gratis) | Pay per use |
| Tiempo setup | <5 min | 30 min | 30 min | 5 min (UI) |
| Métricas técnicas | Básicas | Profundas (PromQL) | Profundas | Profundas |
| Histórico | No | Sí (Prometheus TSDB) | Sí | Sí |
| Alertas | No | Alertmanager | CC nativo | Cloud Monitoring |
| Dashboards custom | No | Sí (ilimitados) | Limitados | Pre-built |
| Curva aprendizaje | Baja | Media-alta (PromQL) | Media | Baja |
| RBAC / seguridad | Limitado | Limitado | Sí | Sí (managed) |

## ¿Cuál usar?

- **Startup / dev**: Kafbat UI + Prometheus/Grafana. Costo cero, suficiente.
- **Empresa media**: Prometheus/Grafana + alertas Alertmanager.
- **Empresa grande con compliance**: Confluent Control Center o Cloud.
- **No queremos operar nada**: Confluent Cloud (managed).

**Realidad**: muchas empresas usan COMBINACIONES. Ejemplo común:
- Confluent Cloud para producción
- Prometheus/Grafana para observabilidad técnica
- Kafbat UI para devs en local

## Reflexión

El curso te dio las 3 visiones. La elección NO es técnica, es de negocio:
costo, equipo disponible, criticidad, compliance.
