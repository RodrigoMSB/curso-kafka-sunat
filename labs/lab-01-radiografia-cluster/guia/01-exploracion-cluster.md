# Parte 1: Exploración del clúster NovaTech

## Objetivo

Familiarizarte con los componentes de un clúster Kafka observando un sistema en producción simulada. Al finalizar esta sección, deberás poder identificar cada componente del clúster, su rol y su estado actual.

## Contexto

Acabas de incorporarte al equipo de plataforma de **NovaTech Logistics**. Tu primera tarea es entender qué hay desplegado en el clúster Kafka que gestiona la telemetría de la flota de vehículos. No toques nada todavía: solo observa, mapea y documenta.

---

## Actividad 1: Reconocimiento de contenedores

Ejecuta el siguiente comando en tu terminal:

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

### Preguntas

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos contenedores están corriendo? | |
| ¿Qué rol cumple `kafka-broker-1`? | |
| ¿Qué rol cumple `kafka-broker-2`? | |
| ¿Qué rol cumple `kafka-broker-3`? | |
| ¿Qué rol cumple `kafbat-ui`? | |
| ¿Qué rol cumple `gps-producer`? | |
| ¿Qué puertos están expuestos en cada broker? | |

---

## Actividad 2: Estado del quorum KRaft

Ejecuta:

```bash
kafka-cli/check-quorum.sh
```

### Preguntas

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Quién es el controlador activo (Leader ID)? | |
| ¿Cuántos votantes tiene el quorum? | |
| ¿Qué IDs tienen los votantes? | |
| ¿Qué significa el campo "Lag" en cada votante? | |
| ¿Qué pasaría si uno de los votantes dejara de responder? | |

---

## Actividad 3: Inspección del tópico GPS

Ejecuta:

```bash
kafka-cli/describe-topics.sh
```

### Preguntas

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene el tópico `novatech.fleet.gps`? | |
| ¿Qué broker es líder de la partición 0? | |
| ¿Qué broker es líder de la partición 3? | |
| ¿Dónde están las réplicas de la partición 1? | |
| ¿Qué significa la columna "Isr"? | |
| ¿Todas las réplicas están sincronizadas (ISR = Replicas)? | |

---

## Actividad 4: Observación de datos en vivo

Ejecuta para ver mensajes en tiempo real:

```bash
kafka-cli/consume-gps.sh
```

Para ver mensajes históricos:

```bash
kafka-cli/consume-gps.sh --history --max 5
```

### Preguntas

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué campos tiene cada mensaje JSON? | |
| ¿Con qué frecuencia llegan los mensajes? | |
| ¿Cuántos vehículos diferentes aparecen? | |
| ¿En qué zona geográfica operan (según lat/lon)? | |
| ¿Qué estados posibles tienen los vehículos? | |

---

## Actividad 5: Grupos de consumidores

Ejecuta:

```bash
kafka-cli/check-consumer-groups.sh
```

### Preguntas

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué grupo de consumidores existe? | |
| ¿Cuántas particiones tiene asignadas? | |
| ¿Cuál es el lag actual del grupo? | |
| ¿Qué significa un lag de 0? | |
| ¿Qué pasaría si el lag creciera continuamente? | |

---

## Siguiente paso

Continúa con la [Parte 2: Mapeo arquitectónico](02-mapeo-arquitectonico.md).
