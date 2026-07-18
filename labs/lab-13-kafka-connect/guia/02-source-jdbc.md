# Parte 2: Source connector JDBC

## Objetivo

Configurar un JDBC Source connector que capture cambios en la tabla `pedidos` de PostgreSQL y los publique al tópico `novatech.lab09.pedidos`.

## Contexto

NovaTech tiene su DB legacy con la tabla `pedidos`. Cualquier pedido nuevo (INSERT) debe aparecer automáticamente en Kafka para que los consumers downstream lo procesen.

---

## Actividad 1: Crear el Source connector

```bash
connect-cli/create-source.sh
```

Esto envía el JSON `infra/connect/jdbc-source-pedidos.json` a la REST API de Connect (POST /connectors).

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La respuesta del API fue 201 Created? | |
| ¿Qué campos JSON se devolvieron? | |

---

## Actividad 2: Verificar estado del connector

```bash
connect-cli/status-connector.sh novatech-source-pedidos
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿`connector.state` es RUNNING? | |
| ¿Cuántas tasks tiene? | |
| ¿`tasks[0].state` es RUNNING? | |
| ¿En qué worker corre? | |

---

## Actividad 3: Verificar que el tópico se creó

```bash
kafka-cli/list-topics.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece `novatech.lab09.pedidos`? | |
| ¿Cuántas particiones tiene? | |

---

## Actividad 4: Consumir los pedidos seed

```bash
kafka-cli/consume-pedidos.sh
```

Espera ~10 segundos para ver los 5 pedidos seed que cargamos en `init-novatech.sql`. Después presiona Ctrl+C.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes leíste? | |
| ¿En qué formato vienen? (JSON, Avro, otro) | |
| ¿Aparecen los campos `id`, `cliente_id`, `producto`, `cantidad`, `monto`, `estado`? | |

---

## Actividad 5: Insertar un pedido nuevo y verlo aparecer en Kafka

En **terminal A**, deja corriendo el consumer:

```bash
kafka-cli/consume-pedidos.sh
```

En **terminal B**, inserta un pedido nuevo:

```bash
kafka-cli/insertar-pedido.sh 2001 "Pedido demo nuevo" 5 25000.00
```

**Mira la terminal A**: en ~5 segundos deberías ver el pedido nuevo aparecer.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Apareció el pedido nuevo en el consumer? | |
| ¿Cuántos segundos tardó? | |
| ¿Por qué tardó ~5s? (pista: `poll.interval.ms`) | |

---

## Actividad 6: Inserción masiva

En **terminal B**, inserta 10 pedidos seguidos:

```bash
for i in 1 2 3 4 5 6 7 8 9 10; do
    kafka-cli/insertar-pedido.sh $((3000+i)) "Pedido masivo $i" $i $((10000*i))
done
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecieron los 10 en el consumer? | |
| ¿En el mismo orden de inserción? | |
| ¿Por qué `mode: incrementing` y no `mode: bulk`? | |

> **Pista**: `bulk` re-publica TODA la tabla cada poll. `incrementing` solo publica filas con id mayor al último visto. Para tablas grandes, bulk es desastroso.

---

## Actividad 7: Inspeccionar offsets del Source connector

```bash
docker exec kafka-broker-1 kafka-console-consumer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic _connect-offsets \
  --from-beginning --max-messages 5 --timeout-ms 5000 \
  --property print.key=true 2>/dev/null
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué información guarda `_connect-offsets`? | |
| ¿Por qué Connect guarda offsets ahí en vez de en archivo local? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasa si tumbas Connect a la mitad de un poll? | |
| ¿Por qué `mode: incrementing` solo detecta INSERT? | |
| ¿Cómo capturarías UPDATE y DELETE? | |

> **Pista respuestas**: Connect guarda el último id visto en `_connect-offsets`. Al reiniciar, continúa desde ahí (sin duplicar). `incrementing` solo mira id ascendente: UPDATE no cambia el id, DELETE saca filas. Para CDC completo, usar Debezium (lee el WAL de PostgreSQL).

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Source connector | Capturó datos de PostgreSQL automáticamente |
| Modo incrementing | Solo INSERT, eficiente |
| Tópico auto-creado | Connect crea el tópico si no existe |
| Offsets persistentes | Connect recuerda dónde quedó al reiniciar |

---

## Siguiente paso

Continúa con [Parte 3: Sink connector JDBC](03-sink-jdbc.md).
