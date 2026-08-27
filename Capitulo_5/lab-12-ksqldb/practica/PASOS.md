# Lab 12 · PASOS

> El recorrido en seco. Aquí están los comandos en orden y los huecos que tú
> rellenas mientras corren. **La explicación de por qué hace cada cosa está en
> la guía** — `guia/01-sql-sobre-lo-que-todavia-no-paso.md`. Este archivo es
> para tener a mano en la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, y 🔴 **los datos sembrados**,
que el `start-lab.sh` **no** hace. Son estos cuatro comandos y tardan **66
segundos medidos**:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido.avsc
schema-cli/register-schema.sh novatech.lab10.clientes-value infra/schemas/cliente.avsc
kafka-cli/produce-flood-pedidos.sh 30
kafka-cli/produce-clientes-seed.sh
```

**Cuánto toma el recorrido:** **17 segundos medidos**, en 4 comandos — y 8 de
ellos son esperar a propósito en el Paso 3.

**Vas a necesitar dos terminales** en el Paso 3.

---

## Paso 1 · Ponerle forma de tabla a un tópico

```bash
curl -s -X POST http://localhost:8088/ksql \
    -H "Content-Type: application/vnd.ksql.v1+json" \
    -d '{"ksql":"CREATE STREAM pedidos_stream (id INT, cliente_id INT, producto VARCHAR, cantidad INT, monto DOUBLE, estado VARCHAR) WITH (KAFKA_TOPIC='"'"'novatech.lab10.pedidos'"'"', VALUE_FORMAT='"'"'AVRO'"'"');"}' \
  | tr ',' '\n' | grep -E '"status"|"message"'
```

| Hueco | Lo que salió |
|---|---|
| `status` | |
| `message` | |

| Pregunta | Tu respuesta |
|---|---|
| ¿Se copió algún mensaje del tópico al crear el stream? | |
| ¿Se creó un tópico nuevo? | |
| Entonces, ¿qué es exactamente lo que se creó? | |

> ⚠️ Si sale `error_code: 40001` y `already exists`, el stream ya estaba de una
> corrida anterior. Sigue al Paso 2.

---

## Paso 2 · Preguntar por lo que ya pasó

```bash
curl -s -X POST http://localhost:8088/query-stream \
    -H "Content-Type: application/vnd.ksqlapi.delimited.v1" \
    -d '{"sql":"SELECT id, producto, monto FROM pedidos_stream EMIT CHANGES LIMIT 3;","properties":{"auto.offset.reset":"earliest"}}'
```

| Hueco | Lo que salió |
|---|---|
| ¿Qué trae la primera línea, antes de las filas? | |
| Los tres `id` que salieron | |

**Ahora el experimento del paso.** Corre **el mismo comando cinco veces
seguidas**, sin cambiar nada, y anota solo los `id`:

| Corrida | Los tres `id` |
|---|---|
| 1 | |
| 2 | |
| 3 | |
| 4 | |
| 5 | |

| Pregunta | Tu respuesta |
|---|---|
| ¿Salieron los mismos tres siempre? | |
| Los datos no cambiaron entre corridas. ¿Por qué cambia el resultado? | |
| ¿Cuántas particiones tiene `novatech.lab10.pedidos`? | |

**La pregunta del paso:** si un informe de SUNAT necesitara los comprobantes en
el orden exacto en que se emitieron, ¿este `SELECT` se lo puede dar? ¿Y qué
haría falta para que sí?

---

## Paso 3 · Preguntar por lo que todavía no pasó

🔴 **Predice antes de ejecutar.** Vas a lanzar la misma consulta cambiando
`earliest` por `latest`, con el tópico quieto:

| Predicción | Tu respuesta |
|---|---|
| ¿Va a dar error? | |
| ¿Va a terminar sola? | |
| ¿Qué crees que va a imprimir? | |

En la **terminal A**:

```bash
curl -s -N -X POST http://localhost:8088/query-stream \
    -H "Content-Type: application/vnd.ksqlapi.delimited.v1" \
    -d '{"sql":"SELECT id, producto, monto FROM pedidos_stream EMIT CHANGES LIMIT 1;","properties":{"auto.offset.reset":"latest"}}'
```

| Hueco | Lo que salió |
|---|---|
| ¿Qué imprimió al instante? | |
| ¿Qué imprimió en los siguientes diez segundos? | |
| ¿Está colgada, rota, o esperando? ¿Cómo lo sabes? | |

**Déjala corriendo.** En la **terminal B**, produce un pedido con un texto que
reconozcas:

```bash
kafka-cli/produce-pedido-avro.sh 777 1001 "Pedido en vivo" 1 99999.99 pendiente
```

**Vuelve a la terminal A.**

| Hueco | Lo que salió |
|---|---|
| ¿Apareció la fila? | |
| ¿Cuántos segundos tardó desde que produjiste? | |
| ¿Cuántas veces escribiste el `SELECT`? | |
| ¿Existía ese dato cuando escribiste el `SELECT`? | |

---

## Cierre · Las tres preguntas del laboratorio

**1 · ¿Qué hace exactamente `EMIT CHANGES`, y qué pasa si lo quitas?**

**2 · Un compañero te dice que su consulta de ksqlDB «no devuelve nada y está
rota». ¿Cuál es la primera cosa que le preguntas?**

**3 · ksqlDB te ahorró escribir una aplicación. ¿Te ahorró también tener que
operarla? ¿Qué sigue habiendo corriendo cuando cierras la terminal?**

---

> **Lo que sigue** — la preparación de los datos, el cliente interactivo de
> ksqlDB, la diferencia entre STREAM y TABLE con su trampa de push contra pull,
> los filtros, las agregaciones y el JOIN están listados en la sección
> **PARA PROFUNDIZAR** de la guía, con su comando completo y su salida medida.
