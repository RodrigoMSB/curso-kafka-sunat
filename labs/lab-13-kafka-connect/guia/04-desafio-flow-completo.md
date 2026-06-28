# Parte 4: Desafío - Flow completo end-to-end

## Objetivo

Conectar todo: insertar pedidos en PostgreSQL → ver en Kafka → publicar "procesados" → ver en otra tabla. Demostrar que NO escribiste código de aplicación, solo configuraste connectors.

## Contexto

Este es el momento "ahá": ves un dato fluir desde una DB → Kafka → otra DB sin haber escrito código de integración. Pura configuración declarativa.

---

## Reto 1: Insertar 5 pedidos nuevos

```bash
for i in 1 2 3 4 5; do
    kafka-cli/insertar-pedido.sh $((5000+i)) "Pedido desafío $i" $i $((5000*i))
done
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos pedidos hay ahora en la tabla `pedidos`? | |

---

## Reto 2: Ver los pedidos llegar a Kafka

En **terminal A**:

```bash
kafka-cli/consume-pedidos.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecen los 5 nuevos? | |
| Anota los `id` que ves en los mensajes | |

Cierra el consumer (Ctrl+C) cuando los hayas visto todos.

---

## Reto 3: "Procesar" los pedidos

Para cada `id` que recibiste, publica un mensaje al tópico de procesados:

```bash
for ID in 6 7 8 9 10; do  # ajusta a los IDs reales que viste
    kafka-cli/publicar-procesado.sh $ID
done
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 5 mensajes se publicaron sin error? | |

---

## Reto 4: Ver los procesados en PostgreSQL

```bash
kafka-cli/verificar-tabla-procesados.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecen los 5 registros en `pedidos_procesados`? | |
| ¿Coinciden con los IDs que publicaste? | |
| ¿Cuánto tiempo total tomó el flujo (insert → procesado en DB destino)? | |

---

## Reto 5: Reflexión final

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas líneas de código escribiste para todo este flujo? | |
| ¿Qué te ahorraste vs hacerlo con un script Python? | |
| ¿Qué pasa si Kafka Connect cae a la mitad del proceso? | |
| ¿En qué se diferencia esto de Debezium para CDC completo? | |
| ¿Qué otros conectores existen en Confluent Hub que podrían ser útiles para NovaTech? | |

> **Pista respuestas**: cero código, solo JSON. Connect maneja resiliencia, paralelismo, offsets, reintentos. Si cae, al volver continúa donde dejó (offsets en `_connect-offsets`). Debezium captura UPDATE/DELETE leyendo el WAL, JDBC solo INSERT con incrementing. Otros conectores: S3 Sink (archivar), Elasticsearch Sink (indexar), MongoDB Source/Sink, Salesforce Source, etc.

---

## Reto 6: Inspección final con Kafbat UI

Abre **http://localhost:8090** > pestaña **Kafka Connect**.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecen los 2 conectores? | |
| ¿Qué información ofrece la UI sobre cada uno? | |
| ¿Puedes ver los mensajes del tópico `novatech.lab09.pedidos`? | |

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md`.

---

## Limpieza (opcional)

Para empezar de cero:

```bash
connect-cli/delete-connector.sh novatech-source-pedidos
connect-cli/delete-connector.sh novatech-sink-procesados
```

O reset completo:

```bash
bin/reset-lab.sh
```
