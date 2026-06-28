# Lab 07 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1-3: DLQ en acción

### Resultado esperado

Con 100 mensajes (10 con `POISON`, 90 normales):
- 90 mensajes con `[OK]` (procesados)
- 10 mensajes con `[DLQ]` (redirigidos a `novatech.lab07.dlq`)
- Verificación: el tópico DLQ contiene exactamente los 10 mensajes venenosos.

### Información perdida en este wrapper simplificado

- **Headers** del mensaje original (cualquier metadata custom).
- **Partición** original (a qué partición del tópico principal correspondía).
- **Offset** original (en qué posición estaba).
- **Timestamp** del producer original.
- **Key** del mensaje (si la tenía).

En producción profesional, la DLQ guardaría todo esto en headers del nuevo mensaje:
- `original.topic`
- `original.partition`
- `original.offset`
- `original.timestamp`
- `error.reason`
- `failure.count`

---

## Reto 4: Reflexión

### ¿Por qué DLQ mejor que skip?

1. **Preserva evidencia**: el mensaje sigue existiendo, alguien puede investigarlo.
2. **Permite re-procesamiento**: si el bug del consumer se fixa, se puede consumir desde la DLQ.
3. **Permite alertas**: si la DLQ crece, hay un problema sistémico que merece atención.
4. **No pierde el negocio**: si el mensaje era un pago real, saltarlo es perder dinero.

### Si el procesador de la DLQ también falla

Opciones de menor a mayor radicalidad:

1. **Alertar y pausar**: notificar al equipo y detener el flujo en la DLQ.
2. **DLQ-de-la-DLQ**: tópico para los mensajes que ni siquiera la DLQ pudo procesar.
3. **Quarantine permanente**: a partir de N fallos, mover a un tópico "morgue" que nadie procesa, solo se inspecciona manualmente.

En la práctica, **la opción 1 es la sana**. Las opciones 2-3 esconden el problema.

### Cómo evitar el loop infinito DLQ→reintento→DLQ

- **Header `failure_count`**: cada vez que un mensaje falla, se incrementa.
- **Política**: si `failure_count > N` (típicamente 3-5), el mensaje no se re-encola; se manda a "morgue" o se alerta.
- **Backoff exponencial**: entre reintentos, aumentar el delay (1s, 2s, 4s, 8s...) para no saturar.

### Retención recomendada para DLQ

- **Tópico principal**: 7 días default.
- **DLQ**: 30-90 días. Razones:
  - Da tiempo al equipo para investigar.
  - Permite re-procesar cuando se fixa el bug.
  - Costo de almacenamiento es bajo (volumen de DLQ << volumen principal).
- **Compactación**: NO usar `cleanup.policy=compact` en DLQ; cada mensaje fallido es único e importante.

---

*Soluciones del desafío - Lab 07*
