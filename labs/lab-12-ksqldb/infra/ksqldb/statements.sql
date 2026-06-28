-- ============================================================
-- NovaTech Lab 10: Statements ksqlDB
-- Crea STREAMS y TABLES sobre los tópicos Avro
-- ============================================================
-- IMPORTANTE: ANTES de ejecutar este archivo, asegurarse que:
--   1. Hay pedidos en novatech.lab10.pedidos (kafka-cli/produce-flood-pedidos.sh 30)
--   2. Hay clientes en novatech.lab10.clientes CON KEY (kafka-cli/produce-clientes-seed.sh)
--   3. La sesión tiene 'auto.offset.reset' en 'earliest':
--        SET 'auto.offset.reset'='earliest';
-- ============================================================

-- STREAM de pedidos (eventos)
CREATE STREAM pedidos_stream (
    id INT,
    cliente_id INT,
    producto VARCHAR,
    cantidad INT,
    monto DOUBLE,
    estado VARCHAR
) WITH (
    KAFKA_TOPIC='novatech.lab10.pedidos',
    VALUE_FORMAT='AVRO'
);

-- TABLE de clientes (estado actual, lookup)
-- KEY_FORMAT='AVRO' es CRÍTICO porque la key fue producida con schema Avro int.
CREATE TABLE clientes_table (
    id INT PRIMARY KEY,
    nombre VARCHAR,
    tipo VARCHAR,
    ciudad VARCHAR
) WITH (
    KAFKA_TOPIC='novatech.lab10.clientes',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO'
);

-- ============================================================
-- Para JOIN: necesitamos un stream re-particionado por cliente_id
-- con el MISMO número de particiones que la TABLE de clientes (3).
-- ksqlDB exige co-partitioning para JOINs stream-table.
-- ============================================================

CREATE STREAM pedidos_rekey
WITH (PARTITIONS=3) AS
SELECT * FROM pedidos_stream PARTITION BY cliente_id;

-- ============================================================
-- Queries de ejemplo (referencia, NO se ejecutan automáticamente)
-- ============================================================

-- Pedidos de alto valor (filtro)
-- CREATE STREAM pedidos_alto_valor AS
--   SELECT * FROM pedidos_stream WHERE monto > 50000;

-- Conteo de pedidos por cliente (agregación stream -> table)
-- CREATE TABLE pedidos_por_cliente AS
--   SELECT cliente_id, COUNT(*) AS total, SUM(monto) AS suma
--   FROM pedidos_stream
--   GROUP BY cliente_id
--   EMIT CHANGES;

-- JOIN: pedidos enriquecidos con datos de cliente
-- (Usa pedidos_rekey, NO pedidos_stream, porque hay que match en particiones)
-- SELECT p.id AS pedido_id, p.producto, p.monto, c.nombre, c.tipo, c.ciudad
--   FROM pedidos_rekey p
--   LEFT JOIN clientes_table c ON p.cliente_id = c.id
--   EMIT CHANGES;
