# Parte 5: Desafío - Dead Letter Queue

## Objetivo

Implementar el patrón Dead Letter Queue (DLQ) usando dos tópicos: el principal donde fluyen todos los eventos, y la DLQ donde se desvían los mensajes "venenosos".

## Contexto

En producción, no todos los mensajes son válidos. Algunos:
- Tienen formato inválido
- Hacen crashear al consumer por bugs
- Vienen de productores defectuosos

**Solución profesional**: el consumer detecta estos mensajes y los **redirige a una DLQ** en vez de fallar. Más tarde, un equipo revisa la DLQ.

---

## Reto 1: Producir mensajes "mixtos"

Vamos a producir 100 mensajes, donde algunos contienen la palabra `POISON`:

```bash
for i in $(seq 1 100); do
    if [ $((i % 10)) -eq 0 ]; then
        # Cada 10 mensajes, uno es "venenoso"
        echo "evento_${i}_POISON_data_corrupta" | docker exec -i kafka-broker-1 kafka-console-producer \
            --bootstrap-server kafka-broker-1:29092 \
            --topic novatech.lab07.eventos 2>/dev/null
    else
        echo "evento_${i}_payload_normal" | docker exec -i kafka-broker-1 kafka-console-producer \
            --bootstrap-server kafka-broker-1:29092 \
            --topic novatech.lab07.eventos 2>/dev/null
    fi
done
echo "✓ 100 mensajes producidos (10 venenosos, 90 normales)"
```

---

## Reto 2: Consumir con DLQ

Usa el wrapper que separa los mensajes:

```bash
kafka-cli/consume-with-dlq.sh --group dlq-test --pattern POISON --max 100
```

Esto procesa los 100 mensajes, mostrando:
- `[OK]` para los normales (se procesarían)
- `[DLQ]` para los venenosos (se redirigen a `novatech.lab07.dlq`)

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos `[OK]` viste? | |
| ¿Cuántos `[DLQ]`? | |
| ¿Los venenosos llegaron al tópico DLQ? (verifica con el comando que muestra el script) | |

---

## Reto 3: Verificar la DLQ

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab07.dlq \
    --from-beginning \
    --max-messages 50 \
    --timeout-ms 5000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Apareció exactamente la cantidad de venenosos? | |
| ¿Qué información perdió el mensaje al pasar a la DLQ? | |

> **Pista**: este wrapper simplificado pierde headers, timestamp original, partición y offset original. En producción, una DLQ profesional **enriquecería** el mensaje antes de mandarlo: agregar headers con `original_topic`, `original_offset`, `error_reason`, `failure_count`, etc.

---

## Reto 4: Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué es mejor DLQ que simplemente saltar el mensaje? | |
| ¿Qué pasa si el procesador de la DLQ también falla? | |
| ¿Cómo evitarías un loop infinito DLQ→reintento→DLQ→reintento? | |
| ¿Qué retención usarías para una DLQ? | |

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md` en la sección del desafío.
