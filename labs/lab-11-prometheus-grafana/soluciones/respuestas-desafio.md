# Lab 11 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Sobre el dashboard 11962 de la comunidad

El dashboard "Kafka Cluster Overview" (Grafana ID 11962) tiene queries
PromQL que asumen ciertas convenciones de nombres de métricas. Las que
JMX Exporter genera con `kafka-broker.yml` pueden no coincidir 1:1.

**Esto es normal y enseñable**: en operación real, importar dashboards
de la comunidad es un buen punto de partida, pero siempre requiere ajustes.

### Cómo diagnosticar paneles "No data"

1. Click en el panel → Edit
2. Mira la query PromQL
3. En Prometheus (http://localhost:9090) prueba la métrica:
   ```promql
   kafka_server_brokertopicmetrics_messagesinpersec_total
   ```
4. Si no existe, busca alternativa:
   ```
   {__name__=~"kafka_server.*"}
   ```
5. Ajusta la query del panel

### Métricas que SÍ funcionan con nuestro setup

- `kafka_server_brokertopicmetrics_bytesinpersec_total`
- `kafka_server_brokertopicmetrics_bytesoutpersec_total`
- `kafka_server_brokertopicmetrics_messagesinpersec_total`
- `kafka_server_replicamanager_underreplicatedpartitions`
- `kafka_controller_kafkacontroller_activecontrollercount`

---

## Sobre Confluent Cloud

### Por qué tour vs práctico

En cursos corporativos:
- Pedir tarjeta de crédito personal a un alumno = problema legal/HR
- La cuenta del instructor se reusa en cada sesión
- El alumno ve el flujo completo, anota observaciones, replica en casa si quiere

### Comparativa real de costos (orientativa)

| Carga | Local (Docker) | Cloud (Basic) | Cloud (Standard) |
|-------|----------------|---------------|------------------|
| 0 mensajes/seg | $0 | $0 (free tier) | ~$50/mes |
| 1.000 msg/seg | $0 (luz) | ~$80/mes | ~$200/mes |
| 100.000 msg/seg | Hardware grande | $1.500-3.000/mes | $5.000-15.000/mes |

**Lección**: Cloud es razonable para producción; local sigue siendo el rey
para dev/staging.

---

## Sobre la comparativa final

### Por qué la elección NO es técnica

Kafka es Kafka en cualquier herramienta de monitoreo. Las diferencias son:

1. **Costo**: open-source = $0 software pero $$ ops; managed = $$$ pero cero ops
2. **Equipo**: ¿tienes personas que puedan operar Prometheus/Grafana?
3. **Criticidad**: ¿qué pasa si tu monitoreo cae 1 hora?
4. **Compliance**: algunos sectores (banca, salud) no pueden enviar datos a Cloud
5. **Velocidad de iteración**: managed permite enfocarse en negocio, no en ops

### Combinaciones reales que funcionan

```
[Producción]
   ├─ Confluent Cloud (Kafka managed)
   ├─ Prometheus + Grafana (métricas detalladas técnicas)
   └─ Datadog/New Relic (correlación con app metrics)

[Desarrollo]
   ├─ Docker local con cp-kafka
   ├─ Kafbat UI (vista rápida)
   └─ ksqlDB local (queries ad-hoc)
```

---

*Soluciones del desafío - Lab 11*
