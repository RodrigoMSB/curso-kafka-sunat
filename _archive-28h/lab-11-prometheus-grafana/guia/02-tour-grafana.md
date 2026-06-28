# Parte 2: Tour por Grafana

## Objetivo

Recorrer el dashboard pre-cargado **Kafka Cluster Overview** (ID 11962 de la comunidad Grafana). Identificar las 4 métricas críticas para operación de Kafka.

## Contexto

El dashboard "Kafka Cluster Overview" es uno de los más populares en Grafana.com (decenas de miles de descargas). Lo cargamos automáticamente vía **provisioning** (los archivos en `infra/grafana/provisioning/`).

---

## Actividad 1: Abrir el dashboard

1. Abre **http://localhost:3000**
2. Login: `admin` / `admin` (o continúa como anónimo)
3. **Dashboards** > **Browse**
4. Click en **Kafka Cluster Overview** (puede aparecer dentro de la carpeta `NovaTech Dashboards`)

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos paneles tiene el dashboard? | |
| ¿Qué tan complejo se ve? | |

---

## Actividad 2: Las 4 métricas críticas

Identifica estos paneles (algunos pueden tener nombres ligeramente distintos):

### Bytes In/Out per second

Throughput de mensajes entrando y saliendo del clúster.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué valores muestra ahora? | |
| ¿Es plano (sin actividad)? | |

### Request Rate

Operaciones por segundo (Produce, FetchConsumer, FetchFollower).

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué tipos de request aparecen? | |

### Under Replicated Partitions

Particiones cuyas réplicas no están sincronizadas. **CRÍTICO**: en operación sana debería ser 0.

| Pregunta | Tu respuesta |
|----------|-------------|
| Valor actual | |
| ¿Por qué debería ser 0? | |

### Active Controllers

Cuántos brokers actúan como controlador del KRaft. **Debería ser exactamente 1** en todo momento.

| Pregunta | Tu respuesta |
|----------|-------------|
| Valor actual | |
| ¿Qué pasaría si fuera 0? | |
| ¿Y si fuera 2? | |

> **Pista**: 0 controllers = clúster sin liderazgo, no acepta cambios. 2 controllers = "split-brain", muy malo. Siempre debe ser exactamente 1.

---

## Actividad 3: Cambiar el rango temporal

En la esquina superior derecha del dashboard:
- Cambia de "Last 6 hours" a "Last 5 minutes"
- Luego a "Last 1 hour"

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las métricas se ven distintas según el rango? | |
| ¿Qué rango es mejor para "ahora mismo"? | |

---

## Actividad 4: Paneles "No data"

Es frecuente que algunos paneles del dashboard de la comunidad muestren "No data" porque las queries PromQL esperan métricas que JMX Exporter no genera con esos nombres exactos.

Identifica al menos 2 paneles "No data" si los hay.

| Panel | Query PromQL que intenta | Posible causa |
|-------|--------------------------|---------------|
| | | |
| | | |

> **Lección**: los dashboards de la comunidad son **punto de partida**, no copy-paste perfecto. Ajustar las queries es parte del trabajo de operaciones.

---

## Actividad 5: Crear tu propia query

En cualquier panel, click "Edit" → modifica la query PromQL. Por ejemplo:

```promql
sum by (instance) (rate(kafka_server_brokertopicmetrics_bytesinpersec_total[1m]))
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecen 3 series (una por broker)? | |
| ¿Las labels (instance) muestran los nombres correctos? | |

---

## Conclusiones

| Concepto | Lo aprendiste explorando... |
|----------|----------------------------|
| Las 4 métricas críticas | Bytes In/Out, Request Rate, URP, Active Controllers |
| Rango temporal | Cambia el contexto de los datos |
| Provisioning Grafana | Dashboards cargados automáticamente |
| "No data" no es bug | Las queries de la comunidad necesitan ajustes |

---

## Siguiente paso

Continúa con [Parte 3: Métricas bajo carga](03-metricas-bajo-carga.md).
