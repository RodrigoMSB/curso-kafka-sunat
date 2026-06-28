# Parte 1: El log inmutable

## Objetivo

Descubrir la propiedad fundamental de Kafka: **los mensajes no se borran cuando se leen**. Son un log inmutable, no una cola.

## Contexto

Antes de mostrarle al jefe cómo resolver el problema de las 3 áreas (Dashboard, Alertas, Reportes), necesitas entender una cosa básica de Kafka que sorprende a todos los que vienen de RabbitMQ o ActiveMQ: **leer un mensaje no lo elimina**.

---

## Actividad 1: Producir mensajes manualmente

Vamos a publicar 5 eventos de la flota.

```bash
kafka-cli/produce-event.sh "vehicle:NVT-1001 event:STARTED"
kafka-cli/produce-event.sh "vehicle:NVT-1002 event:STARTED"
kafka-cli/produce-event.sh "vehicle:NVT-1001 event:STOPPED"
kafka-cli/produce-event.sh "vehicle:NVT-1003 event:STARTED"
kafka-cli/produce-event.sh "vehicle:NVT-1002 event:MAINTENANCE"
```

Cada comando publica 1 mensaje al tópico `novatech.fleet.events`.

---

## Actividad 2: Leer los mensajes

```bash
kafka-cli/consume-event.sh --from-beginning
```

Espera unos segundos, luego presiona **Ctrl+C** cuando hayas visto los 5 mensajes.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes leíste? | |
| ¿En qué orden aparecieron? (¿igual al de producción?) | |

---

## Actividad 3: Volver a leer los mismos mensajes

Aquí viene el momento clave. Ejecuta exactamente el mismo comando OTRA VEZ:

```bash
kafka-cli/consume-event.sh --from-beginning
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecieron los mensajes de nuevo? | |
| Si en otra cola tradicional (RabbitMQ) hubieras hecho esto, ¿qué habría pasado? | |
| ¿Por qué crees que Kafka se comporta así? | |

---

## Actividad 4: Mensajes nuevos sin --from-beginning

Sin `--from-beginning`, el consumidor solo lee mensajes NUEVOS (los que llegan mientras está corriendo).

En una **terminal A**, ejecuta:

```bash
kafka-cli/consume-event.sh
```

(quedará esperando mensajes nuevos)

En una **terminal B**, produce un nuevo mensaje:

```bash
kafka-cli/produce-event.sh "vehicle:NVT-1004 event:STARTED"
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La terminal A vio el mensaje nuevo? | |
| ¿Por qué la terminal A NO vio los 5 mensajes anteriores? | |

---

## Verificación visual en Kafbat UI

1. Abre **http://localhost:8090**
2. Click en **Topics** → **novatech.fleet.events** → pestaña **Messages**
3. Verifica que ves los 6 mensajes (los 5 iniciales + el de la actividad 4)
4. Cada mensaje tiene un **offset** (número único dentro de su partición). Anota:

| Mensaje | Offset | Partición |
|---------|--------|-----------|
| Mensaje 1 | | |
| Mensaje 2 | | |
| Mensaje 3 | | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Log inmutable | Leíste los mismos mensajes 2 veces |
| Posición del consumidor | Sin `--from-beginning` solo viste mensajes nuevos |
| Offset | Cada mensaje tiene un número único permanente |

---

## Siguiente paso

Continúa con la [Parte 2: Pub/Sub con múltiples consumidores](02-pubsub-multiples-consumidores.md).
