# Parte 4: Manejo manual de offsets

## Objetivo

Aprender a manipular offsets para casos especiales: re-procesar desde un timestamp, saltar mensajes, volver a un offset específico.

## Contexto

Por defecto, los consumers manejan offsets automáticamente (auto-commit). Pero a veces necesitas intervenir:
- **Re-procesar** un período específico tras un bug
- **Saltar** un mensaje "venenoso" que está bloqueando el grupo
- **Volver al inicio** de un tópico para una migración

---

## Pre-requisito

Asegúrate de que `novatech.lab07.eventos` tiene mensajes:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab07.eventos \
    --time -1
```

Si los offsets son bajos, produce más:
```bash
kafka-cli/produce-flood.sh 5000
```

---

## Actividad 1: Reset por timestamp

Crea un grupo nuevo y consume algunos mensajes:

```bash
# Terminal A
kafka-cli/consume-with-strategy.sh --group reset-time --strategy cooperative
```

Espera 30 segundos, luego cierra (Ctrl+C).

Verifica el offset actual:
```bash
kafka-cli/describe-group.sh reset-time
```

Anota un timestamp aproximado de hace 5 minutos en formato ISO. Por ejemplo:
```bash
# Linux/Mac:
date -u -v-5M +"%Y-%m-%dT%H:%M:%S.000Z"

# O Linux:
date -u -d '5 minutes ago' +"%Y-%m-%dT%H:%M:%S.000Z"
```

Resetea el grupo a ese timestamp:
```bash
kafka-cli/reset-to-timestamp.sh reset-time <TU_TIMESTAMP>
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió el CURRENT-OFFSET? | |
| ¿Por qué Kafka requiere que NO haya consumers activos para resetear? | |

---

## Actividad 2: Reset a offset específico

Resetea el grupo a offset 0 en la partición 5:

```bash
kafka-cli/reset-to-offset.sh reset-time 5 0
```

Verifica:
```bash
kafka-cli/describe-group.sh reset-time
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Solo cambió la partición 5? | |
| ¿Las demás particiones quedaron como estaban? | |

---

## Actividad 3: Saltar un mensaje "venenoso"

Imagina que el mensaje en la partición 0 offset 100 hace crashear al consumer. Vamos a saltarlo:

```bash
# Asegurar que no hay consumers activos
kafka-cli/describe-group.sh reset-time

# Saltar
kafka-cli/skip-poison-message.sh reset-time 0
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El offset de partición 0 subió en +1? | |
| ¿En producción, qué problema podría tener simplemente saltar mensajes sin más? | |

> **Pista**: si simplemente saltas mensajes problemáticos, **pierdes evidencia** del problema. Por eso en producción se prefiere el patrón Dead Letter Queue (DLQ): mover los mensajes problemáticos a otro tópico antes de saltarlos. Eso lo verás en el desafío.

---

## Conclusiones

| Operación | Cuándo usar |
|-----------|-------------|
| Reset por timestamp | Re-procesar un período específico (post-bug) |
| Reset a offset | Re-procesar desde un punto exacto conocido |
| Skip +1 | Emergencia: saltar mensaje que bloquea (NO RECOMENDADO sin DLQ) |

---

## Siguiente paso

Continúa con [Desafío 5: Dead Letter Queue](05-desafio-dead-letter-queue.md).
