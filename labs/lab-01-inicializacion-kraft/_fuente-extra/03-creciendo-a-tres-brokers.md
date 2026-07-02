# Parte 3: Creciendo a 3 brokers (con quorum)

## Objetivo

Expandir tu clúster de 1 a 3 brokers. Configurar correctamente el `controller.quorum.voters`. Verificar que los 3 forman un quorum KRaft funcional.

## Contexto

Un clúster de un solo broker no tolera fallos. NovaTech necesita resiliencia: 3 brokers que se elijan controlador entre ellos.

---

## Actividad 1: Crear el nuevo docker-compose.yml

```bash
cp plantillas/docker-compose-3-brokers.template.yml mi-cluster/docker-compose.yml
```

Abre `mi-cluster/docker-compose.yml`. Verás que el broker 1 está completo. **Tu trabajo: replicar el bloque para los brokers 2 y 3.**

### Pistas para los brokers 2 y 3

**kafka-broker-2:**
- `KAFKA_NODE_ID: 2`
- Puerto host: `9093`
- Puerto CONTROLLER interno: `39093`
- Puerto PLAINTEXT interno: `29093`
- `KAFKA_LISTENERS: 'PLAINTEXT://kafka-broker-2:29093,CONTROLLER://kafka-broker-2:39093,EXTERNAL://0.0.0.0:9093'`
- `KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka-broker-2:29093,EXTERNAL://localhost:9093'`

**kafka-broker-3:**
- `KAFKA_NODE_ID: 3`
- Puerto host: `9094`
- Puerto CONTROLLER interno: `39094`
- Puerto PLAINTEXT interno: `29094`
- `KAFKA_LISTENERS: 'PLAINTEXT://kafka-broker-3:29094,CONTROLLER://kafka-broker-3:39094,EXTERNAL://0.0.0.0:9094'`
- `KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka-broker-3:29094,EXTERNAL://localhost:9094'`

### El QUORUM_VOTERS (crítico)

Los 3 brokers deben tener EXACTAMENTE este valor:

```
1@kafka-broker-1:39092,2@kafka-broker-2:39093,3@kafka-broker-3:39094
```

### El CLUSTER_ID (crítico)

Debes usar el MISMO CLUSTER_ID en los 3 brokers. Genera uno nuevo:

```bash
kafka-cli/generate-cluster-id.sh
```

Y úsalo en los 3 bloques.

### Volúmenes

No olvides agregar al final:
```yaml
volumes:
  kafka-broker-1-data:
  kafka-broker-2-data:
  kafka-broker-3-data:
```

---

## Actividad 2: Levantar el clúster

Desde `mi-cluster/`:

```bash
docker compose up -d
```

Espera ~30 segundos para que los 3 brokers se descubran y elijan líder.

```bash
docker ps
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 3 contenedores están corriendo? | |
| Si alguno NO arrancó, ¿qué dice `docker logs <nombre>`? | |

---

## Actividad 3: Verificar el quorum

Desde la raíz del lab:

```bash
bin/check-quorum.sh
```

Verás dos secciones:
1. **Estado del quorum**: muestra el LeaderId, LeaderEpoch, etc.
2. **Réplicas del quorum**: muestra los 3 voters con su lag

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál es el LeaderId? | |
| ¿Aparecen los 3 voters? | |
| ¿Qué LAG tienen los voters? | |

> Un LAG bajo (0 o pocos números) indica que los seguidores están sincronizados con el líder.

---

## Actividad 4: Crear un tópico con replicación

Aprovecha que ahora tienes 3 brokers para crear un tópico replicado:

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --create --topic novatech.test \
    --partitions 6 --replication-factor 3
```

> **Nota sobre el WARNING:** Vas a ver un mensaje al crear el tópico que dice:
> ```
> WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
> ```
> Es un warning **informativo, NO un error**. Kafka acepta nombres con `.` perfectamente — el topic se crea y funciona. Lo menciona porque internamente Kafka convierte `.` y `_` a `_` para nombres de métricas JMX, así que dos topics como `foo.bar` y `foo_bar` colisionarían en métricas. Como nuestros topics no colisionan (`novatech.test`, `novatech.fleet.gps`, etc., todos distintos), ignorá el warning. Lo vas a ver en TODOS los labs del curso porque las convenciones NovaTech usan puntos.

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.test
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene? | |
| ¿Cuántas réplicas tiene cada partición? | |
| ¿Quién es el líder de la partición 0? | |
| ¿Qué brokers tiene en su ISR? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Quorum KRaft | Configuraste 3 voters y vista la elección |
| Configuración consistente | Mismo CLUSTER_ID y QUORUM_VOTERS en los 3 brokers |
| Listeners separados | Cada broker tiene PLAINTEXT, CONTROLLER y EXTERNAL en puertos distintos |

---

## Siguiente paso

Continúa con [Parte 4: Chequeo de salud KRaft](04-chequeo-salud-kraft.md).
