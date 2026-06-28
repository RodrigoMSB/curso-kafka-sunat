# Parte 3: Idempotencia y duplicados

## Objetivo

Demostrar empíricamente cómo un productor "naive" puede generar duplicados, y cómo `enable.idempotence=true` los elimina.

## Contexto

Kafka garantiza durabilidad, pero NO garantiza por defecto que un mensaje se publique exactamente una vez. Si el productor reintenta tras un timeout (sin recibir el ACK), el broker puede haber escrito el mensaje ya — el reintento crea un duplicado.

`enable.idempotence=true` resuelve esto: el broker recibe un Producer ID + Sequence Number con cada mensaje, y descarta duplicados automáticamente.

---

## Actividad 1: Producir con productor NAIVE

Limpia primero el tópico (opcional):

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --delete --topic novatech.payments.attempts || true

bash infra/scripts/init-lab06-topics.sh
```

Produce 100 pagos con el productor naive:

```bash
kafka-cli/produce-naive.sh novatech.payments.attempts 100
```

Cuenta cuántos mensajes terminaron en el tópico:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.payments.attempts \
    --time -1
```

Suma los offsets de las 3 particiones.

| Métrica | Valor |
|---------|-------|
| Mensajes producidos | 100 |
| Total en el tópico | |
| ¿Hay diferencia? | |

> **Nota**: en un entorno local sin congestión, puede que NO veas duplicados. El timeout corto los provoca cuando hay latencia. Si no aparecen duplicados, prueba a re-ejecutar el script varias veces seguidas, o reducir el `request.timeout.ms` a 50ms editando el script.

---

## Actividad 2: Producir con productor IDEMPOTENTE

```bash
kafka-cli/produce-idempotent.sh novatech.payments.attempts 100
```

Cuenta de nuevo:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.payments.attempts \
    --time -1
```

| Métrica | Valor |
|---------|-------|
| Mensajes producidos | 100 |
| Total NUEVO (antes + ahora) | |
| Si aplicas la diferencia, ¿son exactamente 100 nuevos? | |

---

## Actividad 3: Verificar configs forzadas

Ejecuta el productor idempotente con `enable.idempotence=true` pero `acks=1`:

```bash
docker exec kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.payments.attempts \
    --producer-property "enable.idempotence=true" \
    --producer-property "acks=1" \
    <<<"test_invalid_config"
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué error apareció? | |
| ¿Por qué `enable.idempotence=true` exige `acks=all`? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué garantiza la idempotencia? | |
| ¿Qué NO garantiza? | |
| Un productor idempotente, ¿es exactly-once dentro de UNA partición? | |
| ¿Es exactly-once a través de MÚLTIPLES particiones? | |

> **Pista de respuesta**: la idempotencia garantiza no-duplicados solo dentro de UN productor + UNA partición + UNA sesión. Si el productor crashea y reinicia, puede haber duplicados. Para exactly-once a través de particiones se necesitan transacciones (Parte 4).

---

## Siguiente paso

Continúa con [Parte 4: Transacciones exactly-once](04-transacciones-exactly-once.md).
