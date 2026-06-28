# Troubleshooting - Lab 10

## Síntoma 1: Schema Registry no responde

**Síntoma**: `curl http://localhost:8081/subjects` da timeout o connection refused.

**Causa**: SR depende de los brokers Kafka. Si los brokers no están healthy, SR no arranca.

**Diagnóstico**:
```bash
docker ps --filter "name=schema-registry"
docker logs schema-registry 2>&1 | tail -30
```

**Solución**:
- Verificar que los 3 brokers están UP (`docker ps`)
- Si SR muestra "Waiting for Kafka...", esperar más (puede tardar 30-60s)

---

## Síntoma 2: `kafka-avro-console-producer` falla con "Subject not found"

**Causa**: la primera vez, SR crea el subject automáticamente cuando recibe el primer mensaje. El error transitorio inicial es normal.

**Solución**: reintentar. Si persiste:
```bash
# Verificar URL de SR
docker exec schema-registry curl -s http://schema-registry:8081/subjects
```

---

## Síntoma 3: ksqlDB Server no arranca o tarda mucho

**Causa**: ksqlDB depende de brokers + Schema Registry. Tarda 60-120s en estar listo.

**Diagnóstico**:
```bash
docker logs ksqldb-server 2>&1 | tail -50
curl http://localhost:8088/info
```

Si en logs ves "READY", está listo.

**Solución**: paciencia. Si tras 3 minutos no responde, revisar dependencias.

---

## Síntoma 4: ksqlDB CLI muestra 0 mensajes en SELECT

**Causa común**: el VALUE_FORMAT del CREATE STREAM no coincide con el formato real del tópico.

**Diagnóstico**:
```sql
SHOW STREAMS;
DESCRIBE EXTENDED PEDIDOS_STREAM;
```

Verificar que `VALUE_FORMAT='AVRO'` coincide con cómo se publicaron los mensajes.

**Solución**: si el tópico tiene mensajes JSON pero el stream dice AVRO, dropear y recrear:
```sql
DROP STREAM pedidos_stream;
CREATE STREAM pedidos_stream (...) WITH (..., VALUE_FORMAT='JSON', ...);
```

---

## Síntoma 5: `CREATE TABLE` falla con "key required"

**Causa**: las TABLE necesitan PRIMARY KEY definida y los mensajes deben tener key en Kafka.

**Diagnóstico**:
```bash
# Verificar que los mensajes de clientes tienen key
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic novatech.lab10.clientes \
  --from-beginning --max-messages 1 \
  --property schema.registry.url=http://schema-registry:8081 \
  --property print.key=true
```

Debe aparecer `<key> <value>` en la salida.

**Solución**: el script `produce-cliente-avro.sh` ya está configurado con `parse.key=true`. Si lo modificaste, restaurar.

---

## Síntoma 6: JOIN no devuelve nada

**Causa común**: los datos del lado TABLE NO existían cuando llegaron los pedidos.

**Diagnóstico**:
```sql
SELECT * FROM clientes_table EMIT CHANGES;
```

Si la TABLE está vacía, el JOIN no encuentra nada.

**Solución**: producir clientes PRIMERO, luego pedidos.

---

## Síntoma 7: Persistent query no se detiene con Ctrl+C

**Causa**: `EMIT CHANGES` es un push query persistente desde el cliente. Ctrl+C cierra el client, pero la persistent query (creada con `CREATE STREAM ... AS`) sigue corriendo.

**Solución**: para eliminar persistent queries:
```sql
SHOW QUERIES;
TERMINATE <query_id>;
```

---

## Síntoma 8: Schema v3 se registra (no debería)

**Causa**: el compatibility level del subject está en NONE en vez de BACKWARD.

**Diagnóstico**:
```bash
curl -s http://localhost:8081/config/novatech.lab10.pedidos-value
```

**Solución**: configurar BACKWARD:
```bash
curl -s -X PUT \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "BACKWARD"}' \
  http://localhost:8081/config/novatech.lab10.pedidos-value
```

---

## Síntoma 9: Conflicto de puertos con labs anteriores

Detener TODOS los demás labs antes:
```bash
# desde labs/<otro-lab>/
bin/stop-lab.sh
```

---

## Síntoma 10: Cambiar puerto Kafbat UI

Ver troubleshooting del Lab 01.

---

## Síntoma: SELECT en ksqlDB se queda "Press CTRL-C to interrupt" sin mostrar datos

### Causa

ksqlDB tarda 30-60 segundos en:
1. Compilar la query (es una app Kafka Streams generada dinámicamente)
2. Asignar particiones del consumer
3. Empezar a leer desde el offset configurado

NO está colgado. Es comportamiento normal.

### Solución

Esperar pacientemente. Si después de 90 segundos no aparece nada:

1. Verificar que el tópico tiene datos:
   ```bash
   kafka-cli/list-topics.sh
   ```
2. Verificar que la sesión tiene `auto.offset.reset='earliest'`:
   ```sql
   SHOW PROPERTIES;
   ```

## Síntoma: TABLE de clientes queda vacía aunque el tópico tiene mensajes

### Causa

Los mensajes se produjeron sin key, o con key en formato distinto al
declarado en el `CREATE TABLE`.

### Diagnóstico

```bash
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic novatech.lab10.clientes \
  --property schema.registry.url=http://schema-registry:8081 \
  --property print.key=true \
  --from-beginning --max-messages 10 --timeout-ms 5000
```

Si la primera columna del output (la key) muestra `null`, los mensajes se
produjeron sin key. Hay que regenerarlos con `kafka-cli/produce-clientes-seed.sh`
(que sí incluye key).

### Solución

1. Borrar la TABLE en ksqlDB: `DROP TABLE clientes_table;`
2. Regenerar clientes con key: `kafka-cli/produce-clientes-seed.sh`
3. Recrear la TABLE asegurándose de incluir `KEY_FORMAT='AVRO'`:
   ```sql
   CREATE TABLE clientes_table (
       id INT PRIMARY KEY, nombre VARCHAR, tipo VARCHAR, ciudad VARCHAR
   ) WITH (
       KAFKA_TOPIC='novatech.lab10.clientes',
       VALUE_FORMAT='AVRO',
       KEY_FORMAT='AVRO'
   );
   ```

## Síntoma: JOIN falla con "number of partitions don't match"

### Causa

ksqlDB exige co-partitioning para JOINs stream-table: ambos lados deben
tener el mismo número de particiones.

`pedidos_stream` apunta a `novatech.lab10.pedidos` (12 particiones).
`clientes_table` apunta a `novatech.lab10.clientes` (3 particiones).
12 ≠ 3 → error.

### Solución

Crear un stream re-particionado con 3 particiones, particionado por `cliente_id`:

```sql
CREATE STREAM pedidos_rekey
WITH (PARTITIONS=3) AS
SELECT * FROM pedidos_stream PARTITION BY cliente_id;
```

Y usar `pedidos_rekey` en el JOIN en lugar de `pedidos_stream`.

### Lección

En diseño de tópicos, si vas a hacer JOIN frecuentemente entre dos tópicos,
es mejor crearlos con el mismo número de particiones desde el inicio.

---

*Troubleshooting - Lab 10*
