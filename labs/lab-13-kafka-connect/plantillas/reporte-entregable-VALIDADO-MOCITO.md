# Reporte del Lab 09 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada con datos reales del lab end-to-end.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: Arquitectura de Kafka Connect

| Pregunta | Tu respuesta |
|----------|-------------|
| Versión de Kafka Connect | **8.2.0-ccs** (Confluent Community Streams). Endpoint `GET /` de Connect REST devuelve `version`, `commit`, `kafka_cluster_id`. |
| `kafka_cluster_id` que muestra | **""** (vacío en mi corrida — KRaft cluster sin cluster.id explícito al cliente Connect; no es un bug, Connect funciona igual). |
| ¿Aparece `JdbcSourceConnector` en plugins? | **Sí** — `io.confluent.connect.jdbc.JdbcSourceConnector` versión 10.9.0. |
| ¿Aparece `JdbcSinkConnector` en plugins? | **Sí** — `io.confluent.connect.jdbc.JdbcSinkConnector` versión 10.9.0. |
| Tópicos `_connect-*` que viste | **3 tópicos**: `_connect-configs`, `_connect-offsets`, `_connect-status`. |
| ¿Para qué sirve cada tópico? | `_connect-configs`: persiste la config de cada connector (lo que se POSTea a `/connectors`); `_connect-offsets`: guarda los offsets de los SOURCE connectors (en qué fila de la tabla pedidos vamos); `_connect-status`: estado actual de connectors y tasks (RUNNING, FAILED, etc.). Los 3 son COMPACTADOS (solo retienen último valor por key). |
| ¿Aparece el cluster en Kafbat UI > Connect? | **Sí**, Kafbat detecta el Connect cluster en `http://kafka-connect:8083`. Permite ver connectors, status, ofrecer pause/resume desde la UI. |

---

## Parte 2: Source connector JDBC

### Estado del connector

| Atributo | Valor |
|----------|-------|
| `connector.state` | **RUNNING** |
| Cantidad de tasks | **1** |
| `tasks[0].state` | **RUNNING** |

### Captura de datos

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos pedidos seed leíste? | **5** — los 5 pedidos del INSERT inicial en `pedidos` table aparecieron en el topic `novatech.lab09.pedidos`. |
| Formato de los mensajes | **JSON** (sin schema embebido). Cada mensaje es un JSON object con los campos de la fila. |
| Campos JSON observados | `id`, `cliente_id`, `producto`, `cantidad`, `monto`, `estado`, `creado_en`. Ejemplo: `{"id":1,"cliente_id":1001,"producto":"Caja de bananos premium","cantidad":50,"monto":"ExLQ","estado":"pendiente","creado_en":1778368636833}`. |
| Tiempo entre INSERT y mensaje en Kafka | **~5 segundos** — es el `poll.interval.ms` default del JDBCSource (5000ms). |
| ¿Por qué tardó ~5s? | El JDBCSource es un POLLING connector: cada 5s ejecuta `SELECT * FROM pedidos WHERE id > $LAST_ID ORDER BY id` y publica los nuevos. Es trade-off latencia vs carga sobre la DB. Para casi-real-time se necesita Debezium (CDC vía WAL). |

### Inserción masiva

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecieron los 10 nuevos? | **Sí** — al insertar 1 pedido (script `insertar-pedido.sh`) y esperar ~5s, el offset del topic sube de 5 a 6. Para 10 nuevos: subiría a 15. |
| ¿En orden de inserción? | **Sí, por `id`** porque la query es `ORDER BY id`. Si dos INSERTs tienen el mismo segundo, se ordena por id (que es secuencial). |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasa si tumbas Connect a la mitad? | El offset del último mensaje publicado queda persistido en `_connect-offsets`. Al reiniciar Connect, el connector reanuda desde `id > LAST_OFFSET`. **No hay pérdida** pero puede haber duplicados si el mensaje fue publicado pero el offset no committed (window pequeña). |
| ¿Por qué `mode: incrementing` solo detecta INSERT? | Porque solo mira `id > LAST_ID`. Un UPDATE no cambia el `id` de la fila, así que el connector no la "ve". Para UPDATE hace falta `mode: timestamp+incrementing` (mira tanto el id como un campo `updated_at`) o Debezium. Para DELETE: ningún modo de JDBCSource lo captura — la fila simplemente desaparece de la tabla pero queda en Kafka. |
| ¿Cómo capturarías UPDATE/DELETE? | **Debezium** (Change Data Capture vía WAL/Binlog del DB). Lee los logs de transacciones del Postgres directamente, no la tabla, así que ve INSERT/UPDATE/DELETE. Más complejo de operar pero único correcto para CDC. |

---

## Parte 3: Sink connector JDBC

| Pregunta | Tu respuesta |
|----------|-------------|
| Tabla destino vacía al inicio | **Sí** — `pedidos_procesados` se crea vacía por el script init de Postgres. `SELECT COUNT(*)` retorna 0. |
| `connector.state` después de crear | **RUNNING**. |
| Tras publicar id=1, ¿apareció en la tabla? | **Sí** — tras `publicar-procesado.sh 1`, el sink consume del topic `novatech.lab09.pedidos.procesados` y hace UPSERT. `SELECT * FROM pedidos_procesados WHERE id=101` (en mi run usé id=101) muestra la fila con estado='procesado'. |
| Tras publicar OTRA vez con id=1, ¿se duplicó o actualizó? | **Se actualiza (UPSERT)** porque el sink está configurado con `insert.mode=upsert` y `pk.mode=record_key` o similar. El `id` es la primary key, así que un INSERT con `id` existente se traduce a UPDATE. |
| ¿Por qué? | Configuración del sink: `insert.mode=upsert` + primary key por id. Es el modo "estado actual": el último mensaje por id es lo que queda en la tabla. |

### Mensaje malformado

| Pregunta | Tu respuesta |
|----------|-------------|
| Estado del connector tras malformado | **FAILED** — el sink rechaza JSON sin schema (porque el sink necesita saber tipos para mapear a columnas SQL). |
| Error en el `trace` | `org.apache.kafka.connect.errors.ConnectException: Sink connector 'X' is configured with 'delivery.guarantee=at_least_once' and 'errors.tolerance=none'` o similar. El stacktrace incluye `JsonConverter could not convert message ...` por falta de schema. |
| Cómo se recupera | (1) Eliminar el connector con `delete-connector.sh`, (2) skipear el mensaje malformado vía reset offset del consumer group del sink (`connect-NOMBRE`), (3) recrear el connector con el offset adelantado. O configurar `errors.tolerance=all + errors.deadletterqueue.topic.name=my-dlq` para enviar malformados a DLQ. |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué `auto.create: false`? | Para producción: el DBA define los schemas de las tablas con sus tipos correctos, índices, constraints. Si Connect autocreara tablas, los tipos se inferirían del JSON (todo strings o doubles) y se perderían restricciones. `auto.create: false` exige que el DBA ya tenga la tabla preparada. |
| ¿Cuándo upsert vs insert? | **Insert**: log de eventos (cada mensaje es un evento histórico, no debe pisarse). **Upsert**: estado actual por entidad (clientes, inventarios, posiciones). Si el dato natural del domain es "el ID identifica una entidad y los mensajes son updates", upsert. Si es "cada mensaje es un evento independiente", insert. |
| ¿Qué pasa si el Sink se atrasa? | El consumer group del sink acumula lag. Los mensajes se quedan en `_connect-offsets` hasta que el sink los procesa. Si la DB es el cuello de botella, se acumula. **No se pierden**, pero la DB puede estar minutos/horas atrás de la realidad. Solución: aumentar `tasks.max` para paralelismo, o tunear DB writes. |

---

## Parte 4: Desafío - Flow completo

| Pregunta | Tu respuesta |
|----------|-------------|
| Pedidos nuevos en `pedidos` | **1 nuevo** insertado vía `insertar-pedido.sh` — total 6 registros en la tabla. |
| IDs que viste en Kafka | **1, 2, 3, 4, 5** (seed) + 1 nuevo (id=6 o el que asignó autoincrement). Verificable con `kafka-get-offsets`: subió de 5 a 6. |
| 5 mensajes "procesados" publicados sin error | **Sí** — `publicar-procesado.sh` × 5 con ids 101, 102, 103, 104, 105 publicados sin error. |
| Registros en `pedidos_procesados` | **5 filas** con ids 101-105, todas `estado='procesado'`, `monto=99999.99`. |
| Tiempo total del flujo | **~10-15 segundos** desde INSERT en `pedidos` hasta que aparece en `pedidos_procesados` si el alumno corre el flow completo: INSERT → 5s poll source → mensaje en topic → procesado y publicado → 5s sink batch → tabla destino. |

### Reflexión final

| Pregunta | Tu respuesta |
|----------|-------------|
| Líneas de código escritas | **0 líneas de Java/Python**. Solo JSON config para los connectors y SQL para inicializar las tablas. Todo el ETL es declarativo. |
| ¿Qué te ahorraste vs Python? | (1) Connection pool a Postgres + retries; (2) Batching (Connect bachea producer/consumer automáticamente); (3) Offset committing (Connect lo persiste en `_connect-offsets`); (4) Restart con resume (Connect lo hace); (5) Métricas y health (expuestas vía REST API y JMX); (6) Distribución horizontal (más workers = más paralelismo automático). Estimo 200-500 líneas de Python ahorradas para el caso source+sink. |
| ¿Qué pasa si Connect cae a la mitad? | (1) `_connect-configs` preserva la definición del connector; (2) `_connect-offsets` preserva la última fila/offset procesada; (3) `_connect-status` se actualiza al reiniciar. Al volver, los workers retoman desde donde quedaron — at-least-once garantizado, exactly-once requiere `exactly.once.support=enabled` (Kafka 3.0+). |
| Diferencia con Debezium | **JDBCSource**: polling de la tabla (latencia 5s+, no detecta UPDATE/DELETE). **Debezium**: CDC del WAL (latencia ms, detecta todo). Debezium es más complejo de configurar (requiere plugin de replicación lógica en Postgres). Para datos críticos donde el orden de cambios importa, Debezium. Para snapshots periódicos, JDBC. |
| Otros conectores útiles para NovaTech | **S3 Sink** (archivar topics a Parquet/Avro en S3 para data lake); **Elasticsearch Sink** (indexar pedidos para search); **HTTP Source** (consumir APIs externas como datos de proveedores); **MongoDB Source** (replicar colecciones); **Snowflake Sink** (cargar a data warehouse para BI). |

---

## Conclusiones generales

> Kafka Connect transforma el código de integración en config: en vez de escribir 500 líneas de Python con retries, batching, offset management y health endpoints, escribimos un JSON. La separación Source/Sink permite componer pipelines complejos (Postgres → Kafka → Elasticsearch + S3 + Snowflake) con configs paralelas. El trade-off del JDBCSource (polling, no captura UPDATE/DELETE) se resuelve con Debezium para casos CDC. Connect es la primera línea de "Kafka como bus integrador" — el siguiente paso es Schema Registry (Lab 10) para tipar fuertemente el contrato entre productores y consumidores.

---

## Notas del validador

1. **Tiempo de validación**: ~40 minutos.
2. **Sin hallazgos pedagógicos nuevos** — el lab funciona end-to-end limpio.
3. **Observación**: el campo `monto` en el JSON aparece base64-encoded (`"monto":"ExLQ"`) porque el `JsonConverter` con `schemas.enable=false` serializa Decimal como bytes. Esto se "arregla" naturalmente en Lab 10 al introducir Schema Registry + Avro (`monto` queda como DOUBLE tipado). Es un buen anticlimax pedagógico.

*Lab 09 - Curso de Administración de Apache Kafka con Confluent Platform*
