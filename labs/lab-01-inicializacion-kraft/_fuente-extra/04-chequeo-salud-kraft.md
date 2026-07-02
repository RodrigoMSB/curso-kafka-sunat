# Parte 4: Chequeo de salud KRaft

## Objetivo

Profundizar en `kafka-metadata-quorum`, la herramienta principal para validar el estado del quorum KRaft.

## Contexto

KRaft sustituye a ZooKeeper como sistema de coordinación de metadatos. Saber leer su estado es esencial para diagnosticar problemas en producción.

---

## Actividad 1: Estado del quorum (modo describe --status)

```bash
docker exec kafka-broker-1 kafka-metadata-quorum \
    --bootstrap-server kafka-broker-1:29092 \
    describe --status
```

### Anota los siguientes campos

| Campo | Valor |
|-------|-------|
| `ClusterId` | |
| `LeaderId` | |
| `LeaderEpoch` | |
| `HighWatermark` | |
| `MaxFollowerLag` | |
| `CurrentVoters` | |
| `CurrentObservers` | |

### Preguntas conceptuales

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué es `LeaderEpoch`? | |
| ¿Qué pasa si el líder muere? ¿Cómo cambian estos valores? | |
| ¿Qué diferencia hay entre `CurrentVoters` y `CurrentObservers`? | |

---

## Actividad 2: Réplicas del quorum (modo describe --replication)

```bash
docker exec kafka-broker-1 kafka-metadata-quorum \
    --bootstrap-server kafka-broker-1:29092 \
    describe --replication
```

Verás una tabla con los 3 brokers como replicators del log de metadatos.

### Anota

| Campo | Valor (broker 1) | Valor (broker 2) | Valor (broker 3) |
|-------|------------------|------------------|------------------|
| `LogEndOffset` | | | |
| `Lag` | | | |
| `LastFetchTimestamp` | | | |
| `LastCaughtUpTimestamp` | | | |

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué significa `Lag` aquí, en el contexto del quorum? | |
| Si un broker tuviera Lag muy alto y `LastCaughtUpTimestamp` antiguo, ¿qué problema indicaría? | |

---

## Actividad 3: Simular el fallo del líder

Identifica el LeaderId actual (de la actividad 1) y mata ese broker:

```bash
docker stop kafka-broker-<NUMERO_LIDER>
```

Espera 10-15 segundos. Luego, desde otro broker:

```bash
docker exec kafka-broker-<OTRO_NUMERO> kafka-metadata-quorum \
    --bootstrap-server kafka-broker-<OTRO_NUMERO>:29092 \
    describe --status
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió el LeaderId? | |
| ¿Cambió el LeaderEpoch? | |
| ¿Cuántos voters quedan disponibles? | |
| ¿El clúster sigue operativo? | |

---

## Actividad 4: Reactivar el broker caído

```bash
docker start kafka-broker-<NUMERO_LIDER>
```

Espera 30 segundos y verifica:

```bash
bin/check-quorum.sh
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El broker volvió como voter o como observer? | |
| ¿Recuperó su rol de líder? | |
| ¿Por qué crees que se mantiene el nuevo líder en vez de "devolver" el liderazgo? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Estado del quorum KRaft | Inspeccionaste con `describe --status` |
| Replicación de metadatos | Vista con `describe --replication` |
| Tolerancia a fallos | Mataste al líder y vista la re-elección |
| Estabilidad de líder | Vista que el nuevo líder se mantiene tras la recuperación |

---

## Siguiente paso

Continúa con el [Desafío 5: Listeners separados](05-desafio-listeners-separados.md) (opcional).
