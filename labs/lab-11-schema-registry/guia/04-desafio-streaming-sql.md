# Guía 04 — Desafío Streaming SQL

## Contexto

NovaTech ya tiene pedidos y clientes fluyendo en Kafka. El equipo de
analytics quiere que tú demuestres queries SQL en tiempo real:

1. Filtrar pedidos de alto valor
2. Contar pedidos por cliente
3. Enriquecer pedidos con datos del cliente (JOIN)

## Pre-requisitos

Antes de empezar, asegúrate de tener datos:

```bash
# Generar 30 pedidos aleatorios
kafka-cli/produce-flood-pedidos.sh 30

# Generar 5 clientes con IDs específicos (necesario para JOINs)
kafka-cli/produce-clientes-seed.sh
```

Los clientes seed tienen IDs `1001, 1010, 1017, 1055, 1098`. Algunos pedidos
del flood pueden coincidir con estos IDs (los cliente_id se generan en el rango
1000-1099). Si no coinciden, **producir un pedido manual** con uno de los IDs
de clientes:

```bash
kafka-cli/produce-pedido-avro.sh 100 1055 "Pedido VIP test" 1 99000.00 pendiente
```

## Abrir ksqlDB

```bash
ksql-cli/ksql-shell.sh
```

**MUY IMPORTANTE**: lo primero que hay que ejecutar dentro de ksqlDB:

```sql
SET 'auto.offset.reset'='earliest';
```

Sin esto, ksqlDB solo verá eventos **futuros**, no los que ya están en el tópico.

## Crear los streams y tables

```sql
-- STREAM de pedidos
CREATE STREAM pedidos_stream (
    id INT, cliente_id INT, producto VARCHAR,
    cantidad INT, monto DOUBLE, estado VARCHAR
) WITH (
    KAFKA_TOPIC='novatech.lab10.pedidos',
    VALUE_FORMAT='AVRO'
);

-- TABLE de clientes — atención al KEY_FORMAT='AVRO'
CREATE TABLE clientes_table (
    id INT PRIMARY KEY, nombre VARCHAR, tipo VARCHAR, ciudad VARCHAR
) WITH (
    KAFKA_TOPIC='novatech.lab10.clientes',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO'
);
```

## Ejercicio 1 — Filtro de alto valor

```sql
SELECT id, cliente_id, producto, monto
FROM pedidos_stream
WHERE monto > 25000
EMIT CHANGES;
```

⏰ **Espera 30-60 segundos**. ksqlDB tarda en compilar la query y empezar a
emitir. No está colgado, es normal.

Verás solo los pedidos con monto mayor a 25.000.

## Ejercicio 2 — Agregación por cliente

```sql
SELECT cliente_id,
       COUNT(*) AS total_pedidos,
       SUM(monto) AS suma_total
FROM pedidos_stream
GROUP BY cliente_id
EMIT CHANGES;
```

Observa cómo el mismo `cliente_id` aparece varias veces: cada nueva fila es
una **actualización del agregado**. Eso es `EMIT CHANGES`: un changelog en
vivo, no una foto.

## Ejercicio 3 — JOIN con re-particionado

**Atención**: para hacer JOIN entre stream y table, ksqlDB exige que ambos
tengan el mismo número de particiones. `pedidos_stream` tiene 12 particiones
y `clientes_table` tiene 3. Por eso hay que re-particionar:

```sql
CREATE STREAM pedidos_rekey
WITH (PARTITIONS=3) AS
SELECT * FROM pedidos_stream PARTITION BY cliente_id;
```

Ahora el JOIN:

```sql
SELECT p.id AS pedido_id, p.producto, p.monto,
       c.nombre, c.tipo, c.ciudad
FROM pedidos_rekey p
LEFT JOIN clientes_table c ON p.cliente_id = c.id
EMIT CHANGES;
```

Verás los pedidos enriquecidos con el nombre, tipo y ciudad del cliente.
Para los pedidos cuyo `cliente_id` no existe en la table, los campos del
cliente saldrán como `null` (eso es lo que hace un `LEFT JOIN`).

## Ejercicio 4 — Filtrar VIPs

Solo los pedidos hechos por clientes tipo VIP:

```sql
SELECT p.id, p.producto, p.monto, c.nombre, c.ciudad
FROM pedidos_rekey p
JOIN clientes_table c ON p.cliente_id = c.id
WHERE c.tipo = 'VIP'
EMIT CHANGES;
```

(Aquí usamos `JOIN` sin `LEFT` porque solo nos interesan los que hacen match.)

## Preguntas para el reporte

1. ¿Qué pasa si publicas un pedido nuevo después de ejecutar el JOIN? ¿Aparece automáticamente?
2. ¿Por qué hubo que re-particionar? ¿No habría sido más simple crear el tópico de clientes con 12 particiones desde el inicio?
3. Si ksqlDB se cae, ¿se pierden los streams creados?
4. ¿Qué diferencia hay entre `STREAM` y `TABLE` después de hacer estos ejercicios?
