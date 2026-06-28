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

## Parte 3: Offsets y replay

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ¿El grupo `reportes` empezó desde el inicio o el final? | Por defecto desde el FINAL (`auto.offset.reset=latest`). Solo recibe mensajes producidos DESPUÉS de su creación |
| ¿Qué CURRENT-OFFSET tienen las particiones después del reset? | **0** en todas |
| ¿El reset de `reportes` afectó al grupo `alertas`? | **No**. Cada grupo tiene sus propios offsets, son independientes |

---

*Solución - Lab 02*
