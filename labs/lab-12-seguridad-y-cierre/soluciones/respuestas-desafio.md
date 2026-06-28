# Lab 12 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

---

## Desafío 1: insertar pedido y verificar que llega al topic

```bash
# 1. Inserción en PostgreSQL
docker exec postgres psql -U novatech -d novatech_orders \
  -c "INSERT INTO pedidos (cliente_id, producto, cantidad, monto, estado)
      VALUES (5001, 'Capstone test', 2, 199.50, 'pendiente');"

# 2. Verifica que el connector está RUNNING
cd labs/lab-09-kafka-connect
connect-cli/status-connector.sh novatech-source-pedidos

# 3. Consume del topic los últimos mensajes (Ctrl+C cuando veas el pedido nuevo)
kafka-cli/consume-pedidos.sh
```

**Por qué funciona**: el JDBC Source connector está configurado en modo `incrementing` o `timestamp+incrementing`, así que cada nuevo `id` insertado en `pedidos` se publica al topic en un par de segundos.

**Si NO funciona**: ver `labs/lab-09-kafka-connect/docs/troubleshooting.md`. Lo más común es que la task del connector esté en `FAILED` (mensaje malformado anterior) — solución: `curl -X POST http://localhost:8083/connectors/novatech-source-pedidos/tasks/0/restart`.

---

## Desafío 2: STREAM con JOIN en ksqlDB

```sql
-- Conectarse:
-- docker exec -it ksqldb-cli ksql http://ksqldb-server:8088

SET 'auto.offset.reset'='earliest';

CREATE STREAM pedidos_capstone (
  pedido_id INT, cliente_id INT, producto VARCHAR, monto DOUBLE
) WITH (
  KAFKA_TOPIC='novatech.lab10.pedidos',
  VALUE_FORMAT='AVRO',
  PARTITIONS=3
);

CREATE TABLE clientes_capstone (
  cliente_id INT PRIMARY KEY, nombre VARCHAR, vip BOOLEAN
) WITH (
  KAFKA_TOPIC='novatech.lab10.clientes',
  VALUE_FORMAT='AVRO',
  KEY_FORMAT='AVRO'
);

CREATE STREAM pedidos_enriquecidos AS
  SELECT p.pedido_id, p.producto, p.monto, c.nombre, c.vip
  FROM pedidos_capstone p
  INNER JOIN clientes_capstone c ON p.cliente_id = c.cliente_id;

SELECT * FROM pedidos_enriquecidos EMIT CHANGES;
```

**Condición clave del JOIN**: co-particionamiento.
- El STREAM `pedidos_capstone` debe estar particionado por `cliente_id` (la key del JOIN).
- La TABLE `clientes_capstone` ya está particionada por su PRIMARY KEY (`cliente_id`).
- Ambos topics deben tener el mismo número de particiones (3 en este lab).

Si los topics no están co-particionados, ksqlDB devuelve:
```
Source topic ... is not co-partitioned with ...
```

Y la solución es hacer un `PARTITION BY cliente_id` antes del JOIN para repartitionar.

---

## Desafío 3: lag y métricas en Grafana

```bash
# Abrir
open http://localhost:3000   # admin/admin
```

**Panels esperados** (del dashboard custom del Lab 11):
- "Brokers UP" — debe mostrar 3 si el cluster está sano.
- "Bytes in/out por broker" — debe haber actividad si produces/consumes.
- "Consumer lag por grupo" — el group del Sink connector aparecerá aquí.
- "Under-replicated partitions" — debe ser 0 en estado normal.

**Métrica para detectar broker no disponible**:
- `up{job="kafka-jmx"} == 0` — Prometheus marca el target como down si no responde el scrape.
- O `count(kafka_server_replicamanager_underreplicatedpartitions) by (instance)` que aumentará si un broker se cae.

**Group con mayor lag**: típicamente el del Sink (`connect-novatech-sink-procesados`) si lo detuviste. El de ksqlDB (`_confluent-ksql-novatech_query_*`) suele tener lag bajo.

---

## Desafío 4: diseño seguro del pipeline

Esto es subjetivo, pero las respuestas mínimas esperadas:

### Lab 09 (Kafka Connect + PostgreSQL)

- Connect autenticado al broker via SASL_SSL con principal `connect-user`.
- ACLs:
  - Read/Write/Describe sobre `connect-configs`, `connect-offsets`, `connect-status`.
  - Read sobre topics origen, Write sobre topics destino.
- PostgreSQL: usuario `novatech-readonly` para el source, con SELECT solo en las tablas necesarias.
- Connection string a PostgreSQL con `ssl=true` y truststore cargado.

### Lab 10 (Schema Registry + ksqlDB)

- Schema Registry con HTTPS (cert generado con la misma CA que el broker).
- Schema Registry con autenticación basic (usuario `sr-reader` para los clientes, `sr-writer` para apps que registren schemas).
- ksqlDB con su propio principal `ksqldb-user` con ACLs sobre topics que crea (`_confluent-ksql-*`) y topics de origen.
- Conexión ksqlDB → Schema Registry vía HTTPS con auth.

### Lab 11 (Prometheus + JMX exporter)

- JMX exporter HTTP detrás de auth básica (`prometheus.yml` con `basic_auth`).
- Prometheus tras reverse proxy con TLS terminator.
- Grafana con SSO en lugar de admin/admin. `GF_AUTH_ANONYMOUS_ENABLED=false`.

### Cluster en general

- TLS en TODOS los listeners (incluido el CONTROLLER).
- SASL/SCRAM-SHA-512 en lugar de PLAIN.
- mTLS para inter-broker (el listener INTERNAL deja de ser PLAINTEXT).
- super.users acotado a un único admin humano más cuentas de servicio justificadas.
- Rotación automática de certificados (Vault PKI, cert-manager).
- Auditoría: `kafka-acls --list` exportado periódicamente a un repo o sistema de gestión.

---

## Desafío 5 (opcional): conectar redes Docker

```bash
# Conectar el container ksqldb-server a la red del Lab 09
docker network connect novatech-lab09-net ksqldb-server

# Verificar
docker inspect ksqldb-server --format '{{json .NetworkSettings.Networks}}' | jq

# Ahora desde la CLI de ksqlDB puedes apuntar a los brokers del Lab 09:
# El bootstrap sería: kafka-broker-1:29092 (broker del Lab 09)
# PERO ojo: hay colisión de hostnames si Lab 10 también tiene "kafka-broker-1".
```

**Problema realista que vas a chocar**: ambos labs nombran a sus brokers `kafka-broker-1`, `kafka-broker-2`, `kafka-broker-3`. Si conectas ksqlDB a la red del Lab 09, el DNS resolverá al broker que Docker decida. Soluciones:

1. **Renombrar los containers** del Lab 09 a `kafka-09-broker-1`, etc. (cambia el compose).
2. **Usar IPs directamente**: `docker inspect kafka-broker-1` (en la red del Lab 09) y usar la IP. Frágil porque cambia al recrear.
3. **El approach realista en producción**: distintos clusters tienen distintos endpoints (DNS records, no nombres de container).

**Conclusión pedagógica**: por eso en producción los labs y entornos viven en DNS distinto y no se cruzan por nombre de container.
