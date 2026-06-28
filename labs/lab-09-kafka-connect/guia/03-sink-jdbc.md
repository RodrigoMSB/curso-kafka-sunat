# Parte 3: Sink connector JDBC

## Objetivo

Configurar un JDBC Sink connector que lea mensajes del tópico `novatech.lab09.pedidos.procesados` y los escriba en la tabla `pedidos_procesados` de PostgreSQL.

## Contexto

NovaTech necesita el flujo inverso: cuando el equipo de fulfillment marque un pedido como "procesado" publicando en un tópico Kafka, ese cambio debe llegar a PostgreSQL automáticamente.

---

## Actividad 1: Verificar que la tabla destino existe y está vacía

```bash
kafka-cli/verificar-tabla-procesados.sh
```

Debería devolver tabla vacía (0 registros).

---

## Actividad 2: Crear el Sink connector

```bash
connect-cli/create-sink.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La respuesta del API fue exitosa? | |

---

## Actividad 3: Verificar estado

```bash
connect-cli/status-connector.sh novatech-sink-procesados
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿`connector.state` es RUNNING? | |
| ¿Cuántas tasks? | |

---

## Actividad 4: Listar todos los conectores activos

```bash
connect-cli/list-connectors.sh
```

Deberías ver 2: el Source y el Sink.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecen los 2 conectores? | |

---

## Actividad 5: Publicar un mensaje "procesado"

```bash
kafka-cli/publicar-procesado.sh 1
```

Esto publica un mensaje JSON al tópico `novatech.lab09.pedidos.procesados` con `id=1`.

> **Importante**: el Sink connector con `value.converter.schemas.enable=true` requiere que cada mensaje tenga el formato:
>
> ```json
> {
>   "schema": { /* declaración de tipos */ },
>   "payload": { /* los datos reales */ }
> }
> ```
>
> Esto es el formato estándar de Kafka Connect cuando se usa JSON con schemas. Por eso `publicar-procesado.sh` envuelve el payload en una estructura con `schema` (declaración de tipos) y `payload` (los datos). En producción real se preferiría usar Avro + Schema Registry para evitar este boilerplate. Lo veremos en el Lab 10.

---

## Actividad 6: Verificar que llegó a PostgreSQL

Espera ~5 segundos, luego:

```bash
kafka-cli/verificar-tabla-procesados.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece el registro con `id=1`? | |
| ¿Qué `estado` tiene? | |
| ¿Qué `procesado_en` tiene? | |

---

## Actividad 7: Probar el upsert

Publica OTRO mensaje con el mismo `id=1`:

```bash
kafka-cli/publicar-procesado.sh 1
```

Espera 5s y verifica:

```bash
kafka-cli/verificar-tabla-procesados.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos registros hay con id=1? | |
| ¿Se duplicó o se actualizó? | |
| ¿Por qué? (pista: `insert.mode: upsert`) | |

---

## Actividad 8: Mensaje malformado (defensa del Sink)

Publica un mensaje SIN el campo `id`:

```bash
echo '{"cliente_id":99,"producto":"sin id","cantidad":1,"monto":1.0,"estado":"x"}' | \
  docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos.procesados
```

Verifica el estado del connector:

```bash
connect-cli/status-connector.sh novatech-sink-procesados
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El connector quedó en estado FAILED? | |
| ¿Qué error muestra el `trace`? | |
| ¿Cómo recuperarías el connector? | |

> **Pista**: `pk.fields: id` exige que el mensaje tenga ese campo. Para recuperar un connector caído: `curl -X POST http://localhost:8083/connectors/<nombre>/restart`.

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué `auto.create: false`? | |
| ¿Qué pasa si la tabla destino no existiera? | |
| ¿`upsert` vs `insert`: cuándo usar cada uno? | |
| ¿Qué pasa si el Sink se queda atrasado? | |

> **Pista respuestas**: con `auto.create: true`, Connect crearía la tabla pero con tipos genéricos. Mejor crearla nosotros con tipos correctos. `upsert` es para idempotencia. Si el Sink se atrasa, los mensajes esperan en Kafka (cola natural).

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Sink connector | Escribió en PostgreSQL desde Kafka |
| Upsert por PK | Sin duplicados, idempotente |
| Tolerancia a malformados | Connector marca FAILED, no pierde estado |
| Restart de connector | Vía REST API |

---

## Siguiente paso

Continúa con [Desafío 4: Flow completo](04-desafio-flow-completo.md).
