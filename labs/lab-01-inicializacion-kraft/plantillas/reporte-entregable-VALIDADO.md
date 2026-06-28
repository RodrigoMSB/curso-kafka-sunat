# Reporte del Lab 03 — VALIDADO POR MOCITO (referencia instructor)

> Versión completada por el agente de validación con datos reales obtenidos al ejecutar el lab end-to-end. Para referencia del instructor.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | Mocito (validador) |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: Anatomía de la imagen Confluent

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué binarios CLI encuentras en `/usr/bin/` que empiecen por `kafka-`? Lista 5. | `kafka-topics`, `kafka-console-producer`, `kafka-console-consumer`, `kafka-consumer-groups`, `kafka-storage`, `kafka-broker-api-versions`, `kafka-acls`, `kafka-configs`, `kafka-get-offsets`, `kafka-metadata-quorum`. La imagen trae ~30+ binarios. |
| ¿En qué directorio están los archivos de configuración de ejemplo? | `/etc/kafka/` (directamente, sin subdirectorio `kraft/`). En CP 8.2 ya no existe `/etc/kafka/kraft/` — los archivos viven en `/etc/kafka/server.properties`, `/etc/kafka/broker.properties`, `/etc/kafka/controller.properties`. En runtime el entrypoint del contenedor genera `/etc/kafka/kafka.properties` a partir de las variables `KAFKA_*`. |
| ¿Cuál es el contenido aproximado del archivo `kraft.properties` de ejemplo? | **[BUG pedagógico: el archivo `kraft.properties` no existe en CP 8.2.0.]** El archivo más cercano es `/etc/kafka/server.properties`, que contiene `process.roles=broker,controller`, `node.id=1`, listeners de ejemplo, `log.dirs=/tmp/kraft-combined-logs`. La pregunta debería referirse a `server.properties` (o eliminarse). El path `kraft/` desapareció en una versión anterior de CP — el fix `6870149` (fase 1) ya corrigió todos los scripts; queda esta pregunta del reporte como rezago. Como acordamos no tocar este archivo, lo dejo marcado pero el alumno se encontrará con el problema en clase. |
| ¿Qué versión de Java trae la imagen? (pista: `java -version`) | **OpenJDK 21.0.10 (Temurin)** — `OpenJDK 64-Bit Server VM Temurin-21.0.10+7 (build 21.0.10+7-LTS, mixed mode, sharing)`. |

---

## Parte 2: Mi primer broker solitario

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál fue el CLUSTER_ID que generaste? | `MkU3OEVBNTcwNTJENDM2Qk` (16 chars base64). En la solución viene fijo; con `kafka-cli/generate-cluster-id.sh` se generan IDs nuevos. |
| ¿Qué pasó cuando intentaste levantar el broker SIN haber formateado el storage? | La imagen `cp-kafka:8.2.0` **AUTO-FORMATEA** el storage si recibe `CLUSTER_ID` por env var y `KAFKA_LOG_DIRS` apunta a un directorio vacío. Por eso al levantar la solución por primera vez no falla aunque el alumno no haya corrido `kafka-storage format` manualmente. Si se modificara el compose para NO pasar CLUSTER_ID, sí daría error tipo "Cluster ID is required". |
| ¿Qué hace exactamente `kafka-storage format`? | Crea el archivo `meta.properties` en cada `log.dirs` registrando `cluster.id`, `directory.id` y `node.id`. Es el equivalente a "particionar el disco" para Kafka — sin ese metadata, el broker no sabe a qué cluster pertenece. Verificable con `kafka-storage info -c /etc/kafka/kafka.properties`. |
| ¿Por qué el `replication.factor` debe ser 1 con un solo broker? | Con `replication.factor > brokers_vivos`, Kafka no tiene dónde colocar las réplicas y lanza `InvalidReplicationFactorException`. Por eso la solución de 1-broker fija `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1`, `KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1`, etc. |
| ¿Qué comando usaste para verificar que el broker está vivo? | `docker exec kafka-broker kafka-broker-api-versions --bootstrap-server kafka-broker:29092` — devuelve la lista de APIs soportadas (Produce, Fetch, etc.). Si responde, el broker está operativo. |

---

## Parte 3: Creciendo a 3 brokers

### Configuración del quorum

`KAFKA_CONTROLLER_QUORUM_VOTERS`:

```
1@kafka-broker-1:39092,2@kafka-broker-2:39093,3@kafka-broker-3:39094
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué los 3 brokers deben compartir el mismo CLUSTER_ID? | Porque KRaft asocia el cluster a una identidad única. Si los brokers tuvieran IDs distintos, cada uno se consideraría parte de un cluster diferente y no formarían quorum (no se "verían" entre sí). El `meta.properties` de cada broker debe coincidir en `cluster.id`. |
| ¿Por qué cada broker tiene un puerto CONTROLLER distinto (39092/39093/39094)? | Cada broker es un proceso JVM independiente: dentro del mismo host (mi laptop) no pueden bindear al mismo puerto. Los 3 brokers viven en la misma red Docker (`mi-cluster_default`), pero como bind a `0.0.0.0:39092/39093/39094` para que cada uno escuche en su propio puerto. En producción real, cada broker estaría en su propia VM/servidor y podrían compartir 39092. |
| ¿Cuál de los 3 brokers fue elegido como Active Controller? | **Broker 2** (LeaderId=2, LeaderEpoch=1) — verificado con `bin/check-quorum.sh`. La asignación es esencialmente aleatoria en el primer arranque (depende de quién levantó primero su Raft y consiguió la mayoría de votos). |
| ¿En base a qué criterio crees que se eligió? | KRaft usa **Raft consensus**: en el arranque, los voters compiten por ser leader. El primero que consigue mayoría (en este caso 2 de 3) gana. No hay preferencia explícita por broker 1, 2 o 3 — depende de timing de inicialización y red. |

---

## Parte 4: Chequeo de salud KRaft

### Salida de `bin/check-quorum.sh`

```
ClusterId:              MkU3OEVBNTcwNTJENDM2Qk
LeaderId:               2
LeaderEpoch:            1
HighWatermark:          116
MaxFollowerLag:         0
MaxFollowerLagTimeMs:   173
CurrentVoters:          [{"id":1,"endpoints":["CONTROLLER://kafka-broker-1:39092"]},
                         {"id":2,"endpoints":["CONTROLLER://kafka-broker-2:39093"]},
                         {"id":3,"endpoints":["CONTROLLER://kafka-broker-3:39094"]}]
CurrentObservers:       []

Réplicas del quorum:
NodeId  LogEndOffset  Lag  Status
2       118           0    Leader
1       118           0    Follower
3       118           0    Follower
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos voters muestra el quorum? | **3 voters**: brokers 1, 2 y 3. Y `CurrentObservers: []` (vacío — todos son voters, no hay observadores). |
| ¿Cuál es el LeaderId actual? | **2** (broker 2 es el Active Controller). |
| ¿Qué significa "Lag"? ¿Qué pasaría si fuera muy alto? | `Lag` = diferencia entre el LogEndOffset del líder y el del seguidor. Mide cuán "atrás" está cada follower en el log de metadatos del controller. **Lag=0** significa que el follower está al día. Si fuera muy alto y `LastCaughtUpTimestamp` antiguo, indicaría un follower lento o desconectado: en KRaft, un follower con lag persistente sale del set de votantes elegibles y el cluster opera con menos redundancia (riesgo si caen más voters). |
| ¿Para qué sirve `--replication` en este comando? | `kafka-metadata-quorum describe --replication` muestra una tabla por nodo con `LogEndOffset`, `Lag`, `LastFetchTimestamp`, `LastCaughtUpTimestamp` y `Status`. Es la vista detallada de salud del quorum, útil para diagnosticar followers atrasados antes de que se conviertan en problema. |

---

## Parte 5: Desafío - Listeners separados (opcional)

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasaría si los 3 listeners (PLAINTEXT, CONTROLLER, EXTERNAL) compartieran el mismo puerto? | **No es posible** — bind al mismo puerto desde la misma JVM falla con `BindException: Address already in use`. Cada listener necesita un puerto único. El propósito de tener 3 listeners es separar el tráfico por canal (cliente externo / inter-broker / control) — comparten interfaz pero no puerto. |
| ¿Por qué `EXTERNAL` se anuncia con `localhost` y no con `kafka-broker-1`? | Porque `EXTERNAL` se diseñó para clientes que se conectan **desde fuera de la red Docker** (desde mi laptop). Esos clientes resuelven `localhost` directo a 127.0.0.1 y golpean el port-forward `9092→9092` del compose. Si el broker se anunciara como `kafka-broker-1`, mi laptop no sabría resolver ese hostname (sólo existe dentro de la red Docker). |
| ¿Qué problema operacional resuelve tener `INTER_BROKER_LISTENER_NAME` distinto al CONTROLLER? | Permite **independizar el plano de datos del plano de control**. Si el listener INTER_BROKER se satura por tráfico de replicación, el CONTROLLER mantiene su capacidad de elegir líderes. También permite políticas de seguridad distintas (ej: TLS+SASL en CONTROLLER, PLAINTEXT en INTER_BROKER si están en VPC privada). |

---

## Conclusiones generales

> Construir un cluster KRaft a mano enseña: (1) la importancia del `CLUSTER_ID` como identidad compartida; (2) el rol crítico del `meta.properties` formateado por `kafka-storage format`; (3) la configuración del quorum vía `controller.quorum.voters` con el formato `id@hostname:puerto`; (4) la separación de listeners para distinguir tráfico de control, inter-broker y cliente externo; (5) que KRaft elimina la dependencia de ZooKeeper haciendo que los mismos brokers cumplan el rol de coordinación de metadatos vía Raft. La elección del Active Controller es dinámica y no preferencial.

---

## Notas del validador

1. **B.4 aplicado**: `guia/03-creciendo-a-tres-brokers.md` actividad 4 ahora explica el WARNING de topics con `.`. El warning literal es:
   ```
   WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide.
   ```
2. **BUG pedagógico identificado**: la pregunta de Parte 1 sobre `kraft.properties` queda con `[BUG]` porque ese archivo no existe en CP 8.2. La instrucción del usuario fue NO modificar el reporte original, así que el alumno se encontrará con el problema. Recomendación: en una v2 del template, cambiar la pregunta a "¿Cuál es el contenido aproximado de `server.properties`?".
3. **Tiempo de validación**: ~50 minutos (start de 1-broker, down, start de 3-brokers, esperas).

*Lab 03 - Curso de Administración de Apache Kafka con Confluent Platform*
