# Parte 5: Desafío - RF, eliminación y recuperación (opcional)

## Objetivo

Profundizar en operaciones avanzadas: cambiar el replication factor de un tópico existente, eliminar tópicos, y entender qué pasa con los datos.

## Contexto

Estos son los temas que diferencia un junior de un senior en operación de Kafka.

---

## Reto 1: Eliminar un tópico de prueba

Crea un tópico desechable:

```bash
kafka-cli/create-topic.sh novatech.test.descartable --partitions 3 --rf 3
kafka-cli/produce-bulk.sh novatech.test.descartable 50
```

Elimínalo:

```bash
kafka-cli/delete-topic.sh novatech.test.descartable
```

Verifica:

```bash
kafka-cli/list-topics.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece en la lista? | |
| ¿Cuánto tardó la eliminación efectiva? | |
| ¿Qué pasa con los datos físicos en disco? | |

> **Pista**: la eliminación no es inmediata. Kafka marca el tópico como "deleted" y los archivos se borran en background.

---

## Reto 2: Aumentar replication factor (operación AVANZADA)

`kafka-topics --alter` **NO permite cambiar el RF**. Para hacerlo, hay que generar un plan de reasignación con `kafka-reassign-partitions`. Vamos a verlo.

Crea un tópico con RF=1:

```bash
kafka-cli/create-topic.sh novatech.test.rf1 --partitions 3 --rf 1
kafka-cli/produce-bulk.sh novatech.test.rf1 100
kafka-cli/describe-topic.sh novatech.test.rf1 | head -8
```

Anota: las 3 particiones tienen 1 sola réplica cada una. Si ese broker muere, pierdes los datos.

### Ahora vamos a aumentar a RF=3

Primero, crea el plan en JSON. Adapta los `LeaderId` que veas en tu `describe`:

```bash
cat > /tmp/reassign-plan.json <<EOF
{
  "version": 1,
  "partitions": [
    {"topic": "novatech.test.rf1", "partition": 0, "replicas": [1, 2, 3]},
    {"topic": "novatech.test.rf1", "partition": 1, "replicas": [2, 3, 1]},
    {"topic": "novatech.test.rf1", "partition": 2, "replicas": [3, 1, 2]}
  ]
}
EOF

docker cp /tmp/reassign-plan.json kafka-broker-1:/tmp/reassign-plan.json
```

Aplica el plan:

```bash
docker exec kafka-broker-1 kafka-reassign-partitions \
    --bootstrap-server kafka-broker-1:29092 \
    --reassignment-json-file /tmp/reassign-plan.json \
    --execute
```

Espera 10-30 segundos, luego verifica:

```bash
docker exec kafka-broker-1 kafka-reassign-partitions \
    --bootstrap-server kafka-broker-1:29092 \
    --reassignment-json-file /tmp/reassign-plan.json \
    --verify
```

```bash
kafka-cli/describe-topic.sh novatech.test.rf1 | head -8
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 3 particiones ahora tienen 3 réplicas? | |
| ¿El ISR está completo? | |
| ¿Por qué Kafka NO permite hacer esto con `--alter` simple? | |

---

## Reto 3: Reflexión final

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué es más peligroso: aumentar particiones o aumentar RF? ¿Por qué? | |
| Si necesitas rollback de un cambio de retention, ¿qué haces? | |
| ¿Qué política recomendarías para `min.insync.replicas` en un tópico de pagos? | |

---

## Limpieza

Elimina los tópicos de prueba que creaste en este desafío:

```bash
kafka-cli/delete-topic.sh novatech.test.rf1
```

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md` en la sección del desafío.
