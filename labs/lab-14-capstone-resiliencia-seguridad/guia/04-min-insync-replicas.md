# Parte 4: min.insync.replicas y el trade-off durabilidad/disponibilidad

## Objetivo

Entender la relación entre `acks=all`, `min.insync.replicas` y el factor de replicación. Verlo en vivo deteniendo brokers.

## Contexto

La configuración del cluster en este lab:

```yaml
KAFKA_DEFAULT_REPLICATION_FACTOR: 3
KAFKA_MIN_INSYNC_REPLICAS: 2
```

Y los topics se crearon con esos defaults: **RF=3, min.ISR=2**.

Esta combinación es el "sweet spot" recomendado para producción y resume el trade-off central de Kafka.

---

## Las tres palancas

Hay tres parámetros que juntos deciden cuán durable y disponible es una escritura:

| Palanca | Dónde se configura | Qué controla |
|---------|--------------------|--------------|
| `replication.factor` | Topic | Cuántas copias de cada partición existen en el cluster |
| `min.insync.replicas` | Topic / broker | Cuántas réplicas deben estar **in-sync** para aceptar escrituras con `acks=all` |
| `acks` | Producer | Cuántas réplicas confirman antes de que el `send()` retorne OK |

La regla práctica que verás repetida en la doc oficial:

> **`replication.factor = min.insync.replicas + 1`**

Con RF=3 y min.ISR=2 puedes **perder un broker** y seguir aceptando escrituras. Si pierdes dos, las escrituras se bloquean (pero los datos no se pierden).

---

## ¿Por qué no `min.ISR=replication.factor`?

Pareciera más seguro decir "RF=3, min.ISR=3". Pero:

- Con min.ISR=3 y RF=3, **un solo broker caído** ya bloquea TODAS las escrituras → bajísima disponibilidad.
- Con min.ISR=2 y RF=3, **un broker caído** sigue aceptando escrituras desde los 2 vivos → buena disponibilidad **y** garantía de durabilidad (los datos están en al menos 2 brokers).

| Pregunta | Tu respuesta |
|----------|-------------|
| Si tienes RF=5, ¿qué min.ISR usarías? | |
| ¿Qué pasa con `acks=1` si min.ISR=2? | |

> **Pista** sobre la segunda: `min.insync.replicas` solo aplica cuando el producer manda `acks=all`. Con `acks=1` la escritura confirma con la sola líder y `min.ISR` se ignora — pero si el líder muere antes de replicar, **pierdes datos**.

---

## Actividad 1: comportamiento normal (3 brokers vivos)

Verifica que el topic `novatech.lab12.publico` esté en estado sano:

```bash
docker exec -e KAFKA_OPTS= cli-client kafka-topics \
  --bootstrap-server kafka-broker-1:9092 \
  --command-config /etc/kafka/client-properties/admin.properties \
  --describe --topic novatech.lab12.publico
```

Deberías ver, para cada partición, algo como:

```
Topic: novatech.lab12.publico  Partition: 0  Leader: 1  Replicas: 1,2,3  Isr: 1,2,3
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas réplicas en ISR por partición? | |

Produce un mensaje:

```bash
kafka-cli/produce-publico.sh "Mensaje normal con 3 brokers"
```

Funciona. Esperado.

---

## Actividad 2: tirar un broker (2 vivos, min.ISR=2 cumplido)

```bash
docker stop kafka-broker-3
sleep 5
```

Verifica el topic:

```bash
docker exec -e KAFKA_OPTS= cli-client kafka-topics \
  --bootstrap-server kafka-broker-1:9092 \
  --command-config /etc/kafka/client-properties/admin.properties \
  --describe --topic novatech.lab12.publico
```

Para algunas particiones verás:

```
Replicas: 1,2,3  Isr: 1,2          ← broker 3 ya no está in-sync
```

Produce de nuevo:

```bash
kafka-cli/produce-publico.sh "Mensaje con 2 brokers vivos"
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Funcionó el produce? | |
| ¿Por qué? | |

> **Esperado**: funciona. ISR=2 cumple `min.insync.replicas=2`.

---

## Actividad 3: tirar otro broker (1 vivo, min.ISR=2 NO cumplido)

```bash
docker stop kafka-broker-2
sleep 10
```

Intenta producir:

```bash
kafka-cli/produce-publico.sh "Mensaje con 1 broker vivo"
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué error apareció? | |
| ¿El cliente reintenta o falla rápido? | |

> **Esperado**: `NotEnoughReplicasException` o `NotEnoughReplicasAfterAppendException`. El producer reintenta hasta `delivery.timeout.ms` y termina fallando. **Los datos NO se perdieron** — simplemente el cluster se niega a aceptar más para no comprometer la durabilidad.

---

## Actividad 4: revivir los brokers

```bash
docker start kafka-broker-2 kafka-broker-3
sleep 30
```

Espera a que los brokers reincorporen y verifica:

```bash
docker exec -e KAFKA_OPTS= cli-client kafka-topics \
  --bootstrap-server kafka-broker-1:9092 \
  --command-config /etc/kafka/client-properties/admin.properties \
  --describe --topic novatech.lab12.publico
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Vuelve ISR a 3? | |
| ¿Cuánto tarda? | |

Produce de nuevo y confirma que el cluster está OK:

```bash
kafka-cli/produce-publico.sh "Cluster recuperado"
```

---

## El trade-off, en una tabla

| Configuración | Tolerancia a fallos | Durabilidad |
|---------------|---------------------|-------------|
| RF=1, min.ISR=1, acks=1 | 0 brokers | Cualquier fallo = pérdida de datos |
| RF=3, min.ISR=1, acks=1 | 2 brokers caídos siguen escribiendo | Líder solo: si muere antes de replicar, pérdida posible |
| RF=3, min.ISR=2, acks=all | 1 broker caído sigue escribiendo | Garantía: dato en al menos 2 brokers antes de OK |
| RF=3, min.ISR=3, acks=all | 0 brokers (cualquier fallo bloquea) | Máxima, pero disponibilidad pésima |

> El default recomendado para producción es la fila 3.

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿En qué casos justificarías RF=5? | |
| ¿Qué pasa si un producer usa `acks=1` en un topic con `min.ISR=2`? | |
| Si pierdes 2 brokers de 3 y vuelven al cabo de 5 minutos, ¿perdiste datos? | |

---

## Siguiente paso

Continúa con [Parte 5: RBAC como concepto (Confluent Enterprise)](05-rbac-concepto.md).
