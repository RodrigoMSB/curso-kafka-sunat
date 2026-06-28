# Lab 09 — Reporte resuelto (solución de referencia)

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
| Versión Connect | 8.2.0 (corresponde a Kafka 4.2) |
| `kafka_cluster_id` | el valor configurado en el broker (ej `novatech-lab09-cluster-9091`) |
| `JdbcSourceConnector` | Sí (instalado vía confluent-hub) |
| `JdbcSinkConnector` | Sí |
| Tópicos `_connect-*` | `_connect-configs`, `_connect-offsets`, `_connect-status` |
| Para qué sirve cada tópico | configs = definiciones de connectors; offsets = posición de cada source/sink; status = estado de tasks |
| Cluster en Kafbat UI | Sí, aparece como `connect-novatech` |

---

## Parte 2: Source connector

### Estado típico

- `connector.state`: RUNNING
- Tasks: 1 (porque `tasks.max=1`)
- `tasks[0].state`: RUNNING

### Captura

- 5 pedidos seed leídos
- Formato: JSON sin schema (`schemas.enable=false`)
- Campos: `id`, `cliente_id`, `producto`, `cantidad`, `monto`, `estado`, `creado_en`
- Latencia INSERT → Kafka: ~5s (por `poll.interval.ms=5000`)

### Reflexión

- **Connect cae a la mitad**: al reiniciar lee `_connect-offsets` para saber el último id procesado. Continúa sin duplicar.
- **`mode: incrementing` solo INSERT**: porque solo detecta nuevos id. UPDATE no cambia id; DELETE saca filas.
- **Capturar UPDATE/DELETE**: usar Debezium (lee el WAL de PostgreSQL).

---

## Parte 3: Sink connector

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Tabla vacía al inicio | Sí (init-novatech.sql crea sin INSERTs en pedidos_procesados) |
| Estado tras crear | RUNNING |
| Mensaje id=1 aparece | Sí, ~3-5s después |
| Re-publicar id=1 | NO se duplica, se actualiza (upsert) |
| Por qué | `insert.mode: upsert` + `pk.fields: id` |

### Mensaje malformado

- Estado: FAILED
- Error: típicamente `DataException: ... missing required field 'id'` o similar
- Recuperación: `curl -X POST http://localhost:8083/connectors/novatech-sink-procesados/restart`

### Reflexión

- **`auto.create: false`**: para tener control sobre tipos de columna. Auto-create usa tipos genéricos.
- **Upsert vs insert**: upsert para idempotencia; insert puro si nunca habrá duplicados de PK.
- **Sink atrasado**: los mensajes esperan en Kafka. Cola natural sin pérdida.

---

## Parte 4: Desafío

### Flujo end-to-end

1. INSERT en pedidos → Source captura en ~5s → publica a Kafka
2. Consumer ve el mensaje
3. Cliente publica al tópico `pedidos.procesados`
4. Sink lo recoge en ~3-5s → INSERT/UPDATE en `pedidos_procesados`

**Tiempo total típico**: 10-15 segundos.

### Reflexión

- **Líneas de código**: cero (solo configs JSON)
- **Vs Python**: Connect maneja resiliencia (reinicia tasks fallidas), paralelismo, offsets, reintentos. En Python tendrías que codificar todo eso.
- **Connect cae a la mitad**: los offsets están en `_connect-offsets`. Al reiniciar, continúa donde dejó. No pierde mensajes ni duplica.
- **Diferencia con Debezium**: JDBC source con `incrementing` solo captura INSERTs. Debezium lee el WAL (Write-Ahead Log) de PostgreSQL y captura INSERT/UPDATE/DELETE en orden, con captura de cambios en tiempo casi real (ms vs segundos).
- **Otros conectores útiles**: S3 Sink (archivar), Elasticsearch Sink (indexar para búsqueda), Snowflake Sink (data warehouse), MongoDB Source (NoSQL), Salesforce Source (CRM), HTTP Source/Sink (APIs).

---

*Solución - Lab 09*
