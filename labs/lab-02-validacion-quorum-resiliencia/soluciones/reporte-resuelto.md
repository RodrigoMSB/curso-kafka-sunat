# Lab 02 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Creciendo a 3 brokers

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

## Parte 2: Chequeo de salud y resiliencia

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Voters | 3 |
| LeaderId | 1, 2 o 3 (varía) |
| Lag | Idealmente 0 o muy bajo |
| `--replication` | Muestra el estado de replicación del log de metadatos por cada réplica del quorum |

---

---

*Solución - Lab 02 (rebanada: quórum y resiliencia)*
