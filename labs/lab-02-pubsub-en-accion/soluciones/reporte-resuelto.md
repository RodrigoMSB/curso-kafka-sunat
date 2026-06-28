# Lab 02 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

---

## Parte 1: El log inmutable

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿Cuántos mensajes leíste la primera vez? | 5 (los 5 que produjo manualmente) |
| ¿Aparecieron de nuevo? | **Sí**, los mismos 5 mensajes |
| Sin `--from-beginning`, ¿qué mensajes ves? | Solo los nuevos producidos mientras el consumer está activo |
| ¿Por qué Kafka se comporta así? | Kafka es un **log inmutable**, no una cola. Los mensajes se mantienen hasta que la política de retención los elimine (por tiempo o tamaño). Múltiples consumidores pueden leerlos múltiples veces |

---

## Parte 2: Pub/Sub con múltiples consumidores

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿Cuántas terminales recibieron el mensaje? | **Las 3** |
| ¿En qué orden llegaron? | Casi simultáneo en las 3, mismo orden |
| ¿Qué habría pasado en RabbitMQ? | **Solo UNA** habría recibido el mensaje (modelo cola con consumo competitivo) |
| ¿Apareció algún grupo? | No, porque consumir SIN grupo usa grupos efímeros que no se persisten |

---

## Parte 3: Consumer Groups

### Distribución esperada

| Cantidad de consumidores | Particiones por consumidor | Total |
|--------------------------|----------------------------|-------|
| 1 | 6 | 6 |
| 2 | 3 y 3 | 6 |
| 3 | 2, 2, 2 | 6 |
| 5 | 2, 1, 1, 1, 1 | 6 (uno tiene 2 porque 6/5 no es entero) |

### Respuestas

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿Algún mensaje fue recibido por más de un consumidor del mismo grupo? | **No**. Dentro del grupo, cada partición pertenece a UN solo miembro |
| Con 5 consumidores y 6 particiones, ¿hay alguno ocioso? | No (los 5 tienen al menos 1 partición) |
| ¿Qué pasaría con 7 consumidores? | Un miembro queda **ocioso** (sin particiones asignadas) |
| ¿Se redistribuyeron las particiones al cerrar uno bruscamente? | **Sí**, después del rebalanceo (~5-10 segundos) |

---

## Parte 4: Offsets y replay

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿El grupo `reportes` empezó desde el inicio o el final? | Por defecto desde el FINAL (`auto.offset.reset=latest`). Solo recibe mensajes producidos DESPUÉS de su creación |
| ¿Qué CURRENT-OFFSET tienen las particiones después del reset? | **0** en todas |
| ¿El reset de `reportes` afectó al grupo `alertas`? | **No**. Cada grupo tiene sus propios offsets, son independientes |

---

## Parte 5: Desafío - Claves y particionado

### Predicción vs realidad

Las particiones exactas dependen del hash, pero lo importante es la **consistencia**:
- La misma clave siempre va a la misma partición.
- La predicción del helper (cksum) puede no coincidir con la real (murmur2). Es una diferencia esperada.

### Reflexión

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿Los 4 eventos de NVT-1001 cayeron en la misma partición? | **Sí, siempre**. Esa es la garantía de Kafka |
| Con 100 vehículos y 6 particiones, ¿cuántos comparten partición? | ~17 vehículos por partición en promedio (100/6) |
| ¿Eso rompe el orden por vehículo? | **No**. Dentro de una partición todo está ordenado. Los vehículos que comparten partición coexisten en orden cronológico, pero el orden POR vehículo se mantiene |

---

*Solución - Lab 02*
