# Parte 2: Carrera contra `min.insync.replicas`

## Objetivo

Entender qué pasa cuando el ISR cae por debajo de `min.insync.replicas`: el productor con `acks=all` se BLOQUEA. Comparar el comportamiento entre dos tópicos con MIR=2 y MIR=3.

## Contexto

`min.insync.replicas` (MIR) es la garantía mínima de durabilidad: solo se confirman escrituras (`acks=all`) si al menos MIR réplicas están en ISR. Si caen por debajo, el productor recibe `NotEnoughReplicasException`.

---

## Actividad 1: Producir al tópico ESTRICTO (MIR=3)

Verifica las configs:

```bash
kafka-cli/describe-topic.sh novatech.lab05.estricto | head -3
```

Espera ver: `Configs: min.insync.replicas=3, ...`

Produce un mensaje (con los 3 brokers vivos):

```bash
echo "test_inicial" | docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.estricto \
    --producer-property acks=all
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Funcionó? | |
| ¿Cuántos brokers están en ISR? | |

---

## Actividad 2: Tumbar UN broker

```bash
bin/kill-broker.sh 3
```

Espera 5 segundos. Verifica el ISR:

```bash
kafka-cli/describe-topic.sh novatech.lab05.estricto | head -10
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos brokers están en ISR ahora? | |
| ¿El ISR (2) es menor que MIR (3)? | |

Intenta producir otro mensaje:

```bash
echo "test_post_kill" | docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.estricto \
    --producer-property acks=all \
    --request-timeout-ms 10000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué error apareció? | |
| ¿Por qué Kafka se niega a aceptar la escritura? | |

> **Esperado**: `NotEnoughReplicasException` o timeout. Kafka prefiere RECHAZAR escrituras antes que aceptar algo que no se puede garantizar durable.

---

## Actividad 3: Comparar con el tópico RESILIENTE (MIR=2)

Sin revivir el broker 3, prueba con `novatech.lab05.resiliente`:

```bash
echo "test_resiliente" | docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.resiliente \
    --producer-property acks=all
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Funcionó? | |
| ¿Por qué SÍ funcionó aquí y NO en el estricto? | |

> **Pista**: el resiliente tiene MIR=2, y todavía hay 2 brokers vivos en ISR. El estricto exige 3.

---

## Actividad 4: Revivir y recuperar

```bash
bin/revive-broker.sh 3
```

Espera 30 segundos. Verifica:

```bash
kafka-cli/describe-topic.sh novatech.lab05.estricto | head -3
```

Intenta producir al estricto otra vez:

```bash
echo "test_recuperado" | docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.estricto \
    --producer-property acks=all
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Volvió a funcionar? | |
| ¿Cuál es la lección sobre `min.insync.replicas=N` con RF=N? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué casi nadie usa `min.insync.replicas=3` con RF=3 en producción? | |
| ¿Qué tradeoff representa MIR=2 con RF=3? | |
| ¿Para un sistema de pagos, qué configuración elegirías? | |

---

## Siguiente paso

Continúa con [Parte 3: Recuperación y catch-up](03-recuperacion-y-catchup.md).
