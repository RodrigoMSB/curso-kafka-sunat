# Parte 5: Desafío - Compactación y tombstones

## Objetivo

Observar la compactación en acción y aprender a usar **tombstones** para eliminar lógicamente claves de un tópico compactado.

## Contexto

Un tópico con `cleanup.policy=compact` retiene **el último mensaje por clave**, indefinidamente. Para "borrar" lógicamente una clave, se publica un mensaje con valor `null` (tombstone). La compactación, eventualmente, elimina tanto los mensajes anteriores como el tombstone mismo.

---

## Reto 1: Llenar el tópico de estado

El tópico `novatech.lab05.estado` está configurado con compactación agresiva:
- `cleanup.policy=compact`
- `min.cleanable.dirty.ratio=0.01` (compacta cuando 1% del log está "sucio")
- `segment.ms=10000` (segmentos de 10 segundos)

Produce 30 actualizaciones para 5 vehículos:

```bash
for round in 1 2 3 4 5 6; do
    for vehicle in 1 2 3 4 5; do
        echo "NVT-${vehicle}:estado_round${round}_v${vehicle}" | \
            docker exec -i kafka-broker-1 kafka-console-producer \
                --bootstrap-server kafka-broker-1:29092 \
                --topic novatech.lab05.estado \
                --property "parse.key=true" \
                --property "key.separator=:"
    done
    sleep 2
done
```

Verifica el offset:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.estado \
    --time -1
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Offset máximo total (suma) | |
| Mensajes producidos | 30 |

---

## Reto 2: Esperar la compactación y verificar

Espera 30-60 segundos para que la compactación se dispare.

Consume desde el principio:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.estado \
    --from-beginning \
    --max-messages 50 \
    --property "print.key=true" \
    --property "key.separator= -> " \
    --timeout-ms 10000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes leíste? | |
| ¿Cuántas claves distintas viste? | |
| ¿Cada vehículo aparece más de una vez? | |
| Si aparece varias veces, ¿la compactación falló? (No: explica) | |

> **Pista**: la compactación garantiza que **eventualmente** quede solo el último mensaje por clave, pero no hay garantía de cuándo. Puede tomar minutos o más. En este lab, el `min.cleanable.dirty.ratio=0.01` hace que se dispare seguido, pero no inmediato.

---

## Reto 3: Tombstone (eliminación lógica)

Imagina que el vehículo NVT-3 fue dado de baja. Quieres eliminar TODO rastro de él.

Envía un tombstone:

```bash
kafka-cli/produce-tombstone.sh novatech.lab05.estado NVT-3
```

Verifica inmediatamente con un consumer:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.estado \
    --from-beginning \
    --max-messages 50 \
    --property "print.key=true" \
    --property "print.value=true" \
    --property "key.separator= -> " \
    --property "null.literal=NULL_VALUE" \
    --timeout-ms 10000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Sigue apareciendo NVT-3 con valores? | |
| ¿Aparece un mensaje NVT-3 -> NULL_VALUE (el tombstone)? | |

Espera 60 segundos para que la compactación procese el tombstone, luego repite el consumer.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Después de 60s, NVT-3 sigue apareciendo? | |
| ¿Qué pasó con sus mensajes anteriores? | |

> **Pista**: los tombstones tienen su propia retención: `delete.retention.ms` (default 24h). Después de la primera compactación, el tombstone permanece para que consumers lentos puedan ver "fue eliminado". Después de 24h, hasta el tombstone desaparece.

---

## Reto 4: Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Para qué casos de uso es ideal `cleanup.policy=compact`? | |
| ¿Por qué necesitas KEY en tópicos compactados? | |
| ¿Qué pasa con un mensaje sin clave (null key) en un tópico compactado? | |
| ¿Por qué los tombstones tienen su propio tiempo de retención? | |

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md` en la sección del desafío.
