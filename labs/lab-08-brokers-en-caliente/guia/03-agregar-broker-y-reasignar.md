# Parte 3: Agregar un broker y reasignar particiones

## Objetivo

Agregar un broker a un clúster en marcha y rebalancear las particiones del tópico hacia él, sin cortar el servicio.

## Contexto

Llega el pico de temporada. NovaTech necesita un broker más. Pero un broker nuevo **no recibe datos automáticamente**: hay que reasignarle particiones explícitamente.

---

## Actividad 1: Foto del estado inicial

Mira cómo están distribuidas las 6 particiones entre los brokers 1–3:

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

### Anota la columna `Replicas` (qué brokers tiene cada partición)

| Partición | Replicas (brokers) |
|-----------|--------------------|
| 0 | |
| 1 | |
| 2 | |
| ... | |

---

## Actividad 2: Agregar el broker 4

```bash
kafka-cli/add-broker.sh
```

Espera a que reporte operativo. Confirma que el clúster ahora ve 4 brokers:

```bash
kafka-cli/list-brokers.sh
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El broker 4 aparece en la lista? | |
| ¿El broker 4 tiene alguna partición del tópico todavía? (vuelve a correr `describe-topic.sh`) | |

> Observa: el broker 4 está en el clúster, pero **vacío**. Agregar capacidad no mueve datos por sí solo.

---

## Actividad 3: Reasignar particiones hacia los 4 brokers

```bash
kafka-cli/reassign-partitions.sh novatech.lab08.pedidos 1,2,3,4
```

El script genera el plan, lo ejecuta y lo verifica. Mientras corre, en otra terminal puedes producir para comprobar continuidad:

```bash
kafka-cli/produce-sample.sh novatech.lab08.pedidos 2000
```

Vuelve a mirar la distribución:

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Ahora el broker 4 tiene particiones asignadas? | |
| ¿La producción de mensajes falló en algún momento durante la reasignación? | |
| ¿Por qué la reasignación no requiere downtime? | |

---

## Siguiente paso

Continúa con [Parte 4: Quitar un broker](04-quitar-broker-y-desafio.md).
