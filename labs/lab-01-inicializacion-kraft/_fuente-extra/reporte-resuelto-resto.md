# Lab 01 — Reporte resuelto: partes movidas (fuente 28h)

> Estas partes (3-5) pertenecían al lab-03 fuente; se conservan aquí como referencia.

## Parte 3: Creciendo a 3 brokers

### QUORUM_VOTERS

```
1@kafka-broker-1:39092,2@kafka-broker-2:39093,3@kafka-broker-3:39094
```

### Respuestas

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿Por qué los 3 deben compartir CLUSTER_ID? | Es la identidad del clúster. Si difieren, KRaft los considera clústers distintos y no se reconocen |
| ¿Por qué puertos CONTROLLER distintos? | Cada broker corre en su propio contenedor, pero comparten la red Docker. Aunque los puertos sean internos, no pueden colisionar dentro del namespace de la red |
| Active Controller | Varía: cualquiera de los 3 (1, 2 o 3). El primero en arrancar y completar la elección |
| Criterio de elección | KRaft usa el algoritmo Raft. El primero que alcanza el quorum y publica un voto vence. En la práctica suele ser el de menor `node.id` que arranca a tiempo |

---

## Parte 4: Chequeo de salud KRaft

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Voters | 3 |
| LeaderId | 1, 2 o 3 (varía) |
| Lag | Idealmente 0 o muy bajo |
| `--replication` | Muestra el estado de replicación del log de metadatos por cada réplica del quorum |

---

## Parte 5: Desafío - Listeners separados

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Listeners en mismo puerto | El broker se niega a arrancar: `IllegalArgumentException: requirement failed: Each listener must have a different port`. Esto previene conflictos de socket |
| EXTERNAL anunciado como `kafka-broker-1` | El cliente del host no puede resolver `kafka-broker-1` porque ese hostname solo existe dentro de la red Docker. Por eso `localhost` es la dirección correcta para clientes externos |
| INTER_BROKER vs CONTROLLER | El tráfico de datos (entre brokers, replicación) y el tráfico de control (quorum, metadatos) se aíslan. Permite aplicar políticas distintas: cifrado, autenticación, QoS |

---

*Solución - Lab 01*
