# Lab 10 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Streaming SQL en producción

Este desafío demuestra capacidades que en producción real reemplazan a aplicaciones Kafka Streams completas.

---

## Reto 1: Persistent query

```sql
CREATE STREAM pedidos_alto_valor AS
  SELECT id, cliente_id, producto, monto, estado
  FROM pedidos_stream
  WHERE monto > 50000;
```

**Lo que pasa por debajo**:
1. ksqlDB compila esta query a una aplicación Kafka Streams.
2. Crea un nuevo tópico Kafka (`PEDIDOS_ALTO_VALOR`) con el resultado.
3. Lanza una task que lee de `pedidos_stream`, filtra, y publica al nuevo tópico.
4. La task corre **indefinidamente** hasta `TERMINATE` o `DROP STREAM`.

Para verificar el tópico creado:
```bash
kafka-cli/list-topics.sh | grep PEDIDOS
```

---

## Reto 2: Agregación con ventana

```sql
SELECT cliente_id, COUNT(*) AS total_pedidos, SUM(monto) AS suma_montos
  FROM pedidos_stream
  WINDOW TUMBLING (SIZE 1 MINUTE)
  GROUP BY cliente_id
  EMIT CHANGES;
```

**TUMBLING window**: ventanas no solapadas, fijas, contiguas. Ejemplo:
- 14:00-14:01 → ventana 1
- 14:01-14:02 → ventana 2
- 14:02-14:03 → ventana 3

Para cada cliente_id, ksqlDB cuenta cuántos pedidos hizo en CADA ventana. Si un cliente hizo 5 pedidos en la ventana 1 y 3 en la 2, aparecen 2 filas distintas.

**Otras ventanas:**
- `HOPPING`: solapadas (ej. ventanas de 5 min cada 1 min)
- `SESSION`: agrupa eventos cercanos en el tiempo

---

## Reto 3: JOIN stream-table

```sql
CREATE STREAM pedidos_enriquecidos AS
  SELECT p.id, p.producto, p.monto, c.nombre, c.tipo, c.ciudad
  FROM pedidos_stream p
  LEFT JOIN clientes_table c ON p.cliente_id = c.id;
```

**Bajo el capó**:
1. Para cada pedido entrante, ksqlDB busca en `clientes_table` por la key.
2. Si encuentra, agrega los campos del cliente al evento de pedido.
3. Si NO encuentra (LEFT JOIN), agrega NULL.
4. Publica al nuevo tópico `PEDIDOS_ENRIQUECIDOS`.

**Diferencia LEFT vs INNER JOIN**:
- LEFT: incluye pedidos aunque el cliente no exista (NULLs).
- INNER: solo incluye pedidos cuyo cliente existe en la TABLE.

**Importante**: la TABLE debe tener datos ANTES de que lleguen los pedidos. Si publicas primero un pedido y luego el cliente, ese pedido se procesará con cliente NULL aunque después aparezca el cliente.

---

## Reto 4: Filtrar VIPs

```sql
SELECT pedido_id, producto, monto, cliente_nombre, cliente_ciudad
  FROM pedidos_enriquecidos
  WHERE cliente_tipo = 'VIP'
  EMIT CHANGES;
```

Esta query es un **push query** sobre el stream `pedidos_enriquecidos`. NO crea un nuevo stream persistente; solo muestra resultados al cliente conectado.

Si quisieras alertar VIPs persistentemente:
```sql
CREATE STREAM alertas_vip AS
  SELECT * FROM pedidos_enriquecidos WHERE cliente_tipo = 'VIP';
```

---

## Reto 5: Reflexión final

### Líneas de Java ahorradas

Cada persistent query ksqlDB equivale a:
- Filtro simple: ~50 líneas Kafka Streams
- Agregación con ventana: ~150 líneas
- JOIN: ~200 líneas

4 queries totales: **~500-700 líneas de Java NO escritas**, ni testeadas, ni desplegadas.

### Reiniciar ksqlDB

ksqlDB persiste sus metadatos (streams, tables, queries) en el tópico interno `_confluent-ksql-novatech_command_topic`. Al reiniciar:
1. Lee ese tópico.
2. Recrea los streams/tables.
3. Vuelve a lanzar las persistent queries.

**No se pierde nada**, solo se interrumpe el procesamiento durante el reinicio (segundos).

### Cuándo NO usar ksqlDB

| Caso | Por qué NO |
|------|-----------|
| Lógica imperativa compleja | SQL es declarativo; bucles complejos requieren código |
| Llamadas a APIs HTTP externas | ksqlDB no soporta side-effects |
| Custom serializers/deserializers | El SDK de Kafka Streams te da más control |
| Algoritmos ML / AI | Necesitas librerías Java/Python |
| Latencia ultra baja (<10ms) | ksqlDB tiene overhead vs código optimizado |

En esos casos, **Kafka Streams en Java** es la respuesta.

### Persistent query bajo el capó

Cada `CREATE STREAM ... AS SELECT ...` o `CREATE TABLE ... AS SELECT ...`:

1. ksqlDB **parsea el SQL** y lo convierte a un plan lógico.
2. Compila el plan a una aplicación **Kafka Streams**.
3. La aplicación tiene su propio:
   - **Application ID** (basado en `service.id` + nombre query)
   - **State stores** (RocksDB local) para agregaciones y joins
   - **Consumer group** (offsets en `__consumer_offsets`)
4. Procesa eventos en tiempo real, escribe al tópico destino.
5. Tolerante a fallos: state stores backup en tópicos `*-changelog`.

Es decir: **ksqlDB es un compilador SQL → Kafka Streams**. Si miras `docker logs ksqldb-server`, verás logs de aplicaciones Kafka Streams arrancando.

---

*Soluciones del desafío - Lab 10*
