# Parte 2: Pub/Sub con múltiples consumidores

## Objetivo

Demostrar que en Kafka, **múltiples consumidores independientes pueden leer los MISMOS mensajes**, sin pisarse. Esto es la diferencia fundamental entre Kafka (log) y una cola tradicional (RabbitMQ).

## Contexto

Recuerda el problema del jefe: las 3 áreas (Dashboard, Alertas, Reportes) necesitan ver los mismos datos GPS. En este experimento, vas a simular las 3 áreas con 3 terminales y verificar que **todas reciben el mismo mensaje al mismo tiempo**.

---

## Actividad 1: Tres consumidores independientes

Abre **3 terminales distintas**. En cada una, ejecuta:

**Terminal A (simula el Dashboard):**
```bash
kafka-cli/consume-event.sh
```

**Terminal B (simula el Sistema de Alertas):**
```bash
kafka-cli/consume-event.sh
```

**Terminal C (simula el módulo de Reportes):**
```bash
kafka-cli/consume-event.sh
```

Las 3 terminales quedarán esperando mensajes nuevos.

---

## Actividad 2: Producir un mensaje y observar

En una **cuarta terminal**, produce 1 mensaje:

```bash
kafka-cli/produce-event.sh "vehicle:NVT-1005 event:CRITICAL_ALERT"
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas terminales recibieron el mensaje? | |
| ¿En cuál llegó primero? | |
| Si esto fuera RabbitMQ, ¿cuántas habrían recibido el mensaje? | |

---

## Actividad 3: Producir varios mensajes seguidos

En la cuarta terminal, ejecuta:

```bash
kafka-cli/produce-event.sh "evento 1"
kafka-cli/produce-event.sh "evento 2"
kafka-cli/produce-event.sh "evento 3"
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 3 terminales recibieron los 3 mensajes? | |
| ¿Llegaron en el mismo orden a las 3 terminales? | |

---

## Actividad 4: Inspeccionar grupos

Detén las 3 terminales con Ctrl+C.

Ejecuta:

```bash
kafka-cli/list-groups.sh
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué grupos aparecen? | |
| ¿Aparece algún grupo de los consumidores que recién usaste? | |

> **Pista**: Cuando consumes SIN especificar un grupo, Kafka asigna nombres aleatorios tipo `console-consumer-XXXXX` (donde XXXXX es un número aleatorio). En Kafka 4.x estos grupos **SÍ quedan registrados** en el topic interno `__consumer_offsets` y aparecen en `list-groups.sh`. Eventualmente se purgan automáticamente cuando vence `offsets.retention.minutes` (default 7 días = 10080 min). Por eso si consumes sin grupo y verificas inmediatamente con `list-groups.sh`, vas a ver una lista de grupos `console-consumer-XXXXX` correspondientes a cada terminal que abriste — son ephemeral en intención (Kafka los limpia solo) pero no son invisibles.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Pub/Sub real | 3 terminales recibieron el mismo mensaje |
| Diferencia vs cola | RabbitMQ habría entregado el mensaje a UNO solo |
| Consumidor sin grupo | Cada terminal era totalmente independiente |

---

## Mapeo a NovaTech

Ahora puedes responderle al jefe:

> *"Las 3 áreas (Dashboard, Alertas, Reportes) pueden conectarse al mismo tópico y cada una recibirá TODOS los mensajes. Kafka no las hace competir por mensajes, las trata como suscriptores independientes."*

Pero falta una pieza: **¿qué pasa si el área de Alertas recibe tanto volumen que un solo consumidor no da abasto?** Eso lo resolvemos en la siguiente parte.

---

## Siguiente paso

Continúa con la [Parte 3: Consumer Groups y escalado horizontal](03-consumer-groups.md).
