# Parte 3: ksqlDB fundamentos

## Objetivo

Entender la diferencia entre STREAM y TABLE en ksqlDB. Crear los primeros streams sobre tópicos Avro. Hacer queries en tiempo real con `EMIT CHANGES`.

## Contexto

**ksqlDB** permite escribir **SQL contra streams de Kafka**. Detrás de cámaras, cada query persistent se compila a una aplicación Kafka Streams.

**Conceptos clave:**

| Concepto | Definición |
|----------|------------|
| **STREAM** | Eventos inmutables, append-only. Cada mensaje es un evento histórico. Ej: pedidos. |
| **TABLE** | Estado actual por key. El último mensaje por clave "gana". Ej: estado actual de cada cliente. |
| **Persistent Query** | Query que corre indefinidamente, materializa resultados a un nuevo tópico. |
| **Push Query** (`EMIT CHANGES`) | Devuelve nuevos resultados a medida que llegan eventos. |

---

## Actividad 1: Abrir el CLI de ksqlDB

```bash
ksql-cli/ksql-shell.sh
```

Deberías ver un prompt `ksql>`.

```sql
SHOW STREAMS;
SHOW TABLES;
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Hay streams o tables al inicio? | |

(Pueden aparecer KSQL_PROCESSING_LOG, que es interno.)

---

## Actividad 2: Crear el STREAM de pedidos

En el prompt `ksql>`:

```sql
CREATE STREAM pedidos_stream (
    id INT,
    cliente_id INT,
    producto VARCHAR,
    cantidad INT,
    monto DOUBLE,
    estado VARCHAR
) WITH (
    KAFKA_TOPIC='novatech.lab10.pedidos',
    VALUE_FORMAT='AVRO',
    PARTITIONS=12
);
```

```sql
SHOW STREAMS;
DESCRIBE pedidos_stream;
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece `PEDIDOS_STREAM`? | |
| ¿Qué columnas tiene? | |
| ¿Qué tipo es cada columna? | |

> **Pista**: ksqlDB convierte nombres a UPPERCASE por default. Eso es normal.

---

## Actividad 3: Primer SELECT con EMIT CHANGES

```sql
SELECT * FROM pedidos_stream EMIT CHANGES;
```

Esto es un **push query**: queda escuchando indefinidamente. Verás los pedidos ya producidos + cualquiera nuevo.

En **otra terminal** (no cerrar el ksqlDB shell), ejecuta:

```bash
kafka-cli/produce-pedido-avro.sh 7 1001 "Pedido nuevo en vivo" 1 9999.99 pendiente
```

Vuelve al ksqlDB shell:

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Apareció el pedido nuevo en tiempo real? | |
| ¿Cuánto tardó (segundos)? | |

Para detener el push query: Ctrl+C (vuelves al prompt `ksql>`).

---

## Actividad 4: Filtros con WHERE

```sql
SELECT id, producto, monto FROM pedidos_stream WHERE monto > 50000 EMIT CHANGES;
```

En otra terminal:
```bash
kafka-cli/produce-pedido-avro.sh 8 1002 "Compra grande" 1 75000 pendiente
kafka-cli/produce-pedido-avro.sh 9 1003 "Compra chica" 1 5000 pendiente
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecieron los 2? | |
| Si NO, ¿por qué? | |

> **Pista**: Solo aparecen los que cumplen `monto > 50000`. La query filtra en streaming.

Ctrl+C para volver al prompt.

---

## Actividad 5: Crear el TABLE de clientes

```sql
CREATE TABLE clientes_table (
    id INT PRIMARY KEY,
    nombre VARCHAR,
    tipo VARCHAR,
    ciudad VARCHAR
) WITH (
    KAFKA_TOPIC='novatech.lab10.clientes',
    VALUE_FORMAT='AVRO',
    PARTITIONS=3
);
```

```sql
SHOW TABLES;
SELECT * FROM clientes_table EMIT CHANGES;
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecieron los 4 clientes producidos en Parte 2? | |
| ¿Por qué la TABLE necesita PRIMARY KEY pero el STREAM no? | |

> **Pista**: la TABLE materializa estado por key. Sin key no puede saber qué fila reemplazar. El STREAM es solo append, no necesita key.

---

## Actividad 6: Diferencia conceptual STREAM vs TABLE

Produce el cliente 1001 dos veces con datos distintos:

```bash
# Desde otra terminal
kafka-cli/produce-cliente-avro.sh 1001 "Acme S.A. - actualizado" VIP Santiago
```

En ksqlDB:

```sql
SELECT * FROM clientes_table EMIT CHANGES;
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas veces aparece cliente 1001? | |
| ¿Con qué nombre? | |

> **Pista**: si publicas 2 mensajes con la misma key, la TABLE muestra solo el ÚLTIMO (estado actual). Si fuera un STREAM, mostraría AMBOS (eventos históricos). Esa es la diferencia.

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuándo usar STREAM vs TABLE? | |
| ¿`EMIT CHANGES` qué significa exactamente? | |
| ¿La query persistent dura para siempre? | |

> **Pista**: STREAM para eventos (logs, transacciones, mediciones). TABLE para estado (perfiles, configuración, último valor). `EMIT CHANGES` = push: escucha siempre. Sin él, ksqlDB devuelve un snapshot puntual ("pull query"). Las persistent queries duran hasta `DROP STREAM`.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| STREAM (append-only) | Pedidos como eventos |
| TABLE (estado actual) | Clientes con PRIMARY KEY |
| Push query | `SELECT ... EMIT CHANGES` |
| Filtro | `WHERE monto > 50000` |

---

## Cierre

Sal del ksqlDB shell con `exit` o Ctrl+D.

---

## Siguiente paso

Continúa con [Desafío 4: Streaming SQL completo](04-desafio-streaming-sql.md).
