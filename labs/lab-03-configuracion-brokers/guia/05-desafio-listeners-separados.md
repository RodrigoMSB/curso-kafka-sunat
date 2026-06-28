# Parte 5: Desafío - Listeners separados (opcional)

## Objetivo

Entender en profundidad por qué un broker Kafka necesita múltiples listeners (PLAINTEXT, CONTROLLER, EXTERNAL) y qué pasa si los configuras mal.

## Contexto

En el docker-compose de la Parte 3, configuraste tres listeners distintos:
- `PLAINTEXT` para comunicación entre brokers (puerto interno 29092/29093/29094)
- `CONTROLLER` para el quorum KRaft (puerto interno 39092/39093/39094)
- `EXTERNAL` para clientes desde el host (puerto público 9092/9093/9094)

¿Por qué tantos? Vamos a romperlo intencionalmente para entender.

---

## Reto 1: Colapsar listeners

Detén tu clúster:
```bash
cd mi-cluster
docker compose down -v
```

Edita el `docker-compose.yml` y, **solo en kafka-broker-1**, modifica:

```yaml
KAFKA_LISTENERS: 'PLAINTEXT://kafka-broker-1:9092,CONTROLLER://kafka-broker-1:9092'
```

(Mismo puerto para PLAINTEXT y CONTROLLER. Y elimina EXTERNAL.)

Levanta:
```bash
docker compose up -d
```

### Observa

```bash
docker logs kafka-broker-1 2>&1 | tail -30
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El broker arrancó? | |
| ¿Qué error específico aparece en los logs? | |
| ¿Por qué no se permite que dos listeners compartan puerto? | |

**Restaura la configuración original antes de continuar.**

---

## Reto 2: Advertised listeners incorrectos

Detén el clúster (`docker compose down -v`) y modifica el `kafka-broker-1`:

```yaml
KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka-broker-1:29092,EXTERNAL://kafka-broker-1:9092'
```

(El EXTERNAL se anuncia con el hostname interno `kafka-broker-1` en vez de `localhost`.)

Levanta el clúster.

Desde tu Mac, intenta conectarte:
```bash
docker run --rm confluentinc/cp-kafka:8.2.0 kafka-broker-api-versions \
    --bootstrap-server localhost:9092
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La conexión funciona? | |
| Si NO, ¿qué error aparece? | |
| ¿Por qué el `advertised.listener` debe usar un nombre que el cliente pueda resolver? | |

**Restaura la configuración original antes de continuar.**

---

## Reto 3: Reflexión

Responde con tus palabras:

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué Kafka necesita un listener CONTROLLER separado en KRaft? | |
| ¿Qué problema operacional resuelve tener `INTER_BROKER_LISTENER_NAME` distinto al CONTROLLER? | |
| Si tu clúster está dentro de Docker pero los clientes están en el host, ¿qué listener usas para cada comunicación? | |

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md` en la sección del desafío.
