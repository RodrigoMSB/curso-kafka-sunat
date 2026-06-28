# Lab 07 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Estrategias de asignación

### Comportamiento esperado con 12 particiones y 3 consumers

| Estrategia | Asignación esperada |
|-----------|---------------------|
| Range | Consumer 1: [0,1,2,3], Consumer 2: [4,5,6,7], Consumer 3: [8,9,10,11] |
| RoundRobin | Consumer 1: [0,3,6,9], Consumer 2: [1,4,7,10], Consumer 3: [2,5,8,11] |
| Sticky | Similar a RoundRobin, pero al rebalancear MANTIENE la asignación previa |
| CooperativeSticky | Igual a Sticky pero con rebalanceo INCREMENTAL (los no afectados siguen procesando) |

### Sticky agregando un 4to consumer

- **Antes (3 consumers)**: ~4 particiones por consumer
- **Después (4 consumers)**: 3 particiones por 3 de ellos, 3 por el cuarto
- **Particiones movidas**: típicamente 2-3 (las que se ceden al nuevo). Sticky minimiza el movimiento.

### Por qué importa minimizar re-asignación

- Cada re-asignación implica **commit offsets, descartar batches en memoria, re-fetch desde brokers**.
- Si una partición cambia de dueño, el nuevo consumer debe esperar al commit previo y empezar desde ahí.
- En producción con miles de mensajes/segundo, mover muchas particiones = pausa larga y duplicado-procesamiento si commits no estaban al día.

---

## Parte 2: Lag

### Métricas típicas

- **LAG inicial (2 consumers, sin carga)**: 0 o muy bajo (los consumers procesan al instante).
- **Tras flood de 50K**: lag total sube rápido a 30K-50K mientras los 2 consumers hacen catch-up.
- **Con 6 consumers**: el lag baja en ~30-90 segundos.
- **Con 14 consumers vs 12 particiones**: 2 consumers idle. Es desperdicio.

---

## Parte 3: Rebalanceo

### Métricas típicas

| Estrategia | Tiempo rebalanceo | Stop-the-world |
|-----------|-------------------|----------------|
| Eager (Range) | 5-15 segundos | Sí, todos los consumers paran |
| CooperativeSticky | 2-5 segundos | No, los consumers no afectados siguen procesando |

### Recomendación

CooperativeSticky para producción. Eager solo en clústers muy chicos donde el overhead del cooperative no compensa.

---

## Parte 4: Offsets

### Reset por timestamp

- Cambia CURRENT-OFFSET a la posición del primer mensaje con timestamp >= TS.
- Requiere consumers inactivos: si hay un consumer activo, el coordinator no puede tomar control de los offsets sin causar inconsistencias.

### Reset a offset específico

- Solo afecta la partición especificada.
- Las demás permanecen igual.

### Skip poison message

- Sube el offset en +1.
- **Problema**: el mensaje se pierde sin trazabilidad. No sabes qué tenía, por qué falló, ni cómo evitar que vuelva a pasar.
- **Solución**: DLQ (Parte 5).

---

## Parte 5: Dead Letter Queue

### Comportamiento esperado

- **[OK]**: 90 mensajes
- **[DLQ]**: 10 mensajes
- **DLQ topic**: 10 mensajes
- **Información perdida**: headers, timestamp original, partición, offset, key (si los hubiera).

### Reflexión

- **Por qué DLQ mejor que skip**: preserva el mensaje para análisis post-mortem; permite re-procesarlo después de fixearlo; permite alertar (si DLQ crece, hay un bug).
- **Si el procesador DLQ falla**: tener una "DLQ de la DLQ" es una opción extrema; lo más sano es alertar al equipo y pausar el flujo.
- **Loop infinito**: usar header `failure_count` y descartar (o mover a "morgue") tras N reintentos.
- **Retención DLQ**: típicamente más larga que el tópico principal (30-90 días) para dar tiempo a investigar.

---

*Solución - Lab 07*
