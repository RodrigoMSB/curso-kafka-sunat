# Lab 05 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: ISR bajo el microscopio

### Estado inicial esperado

Las 6 particiones tienen `Replicas: [N1, N2, N3]` y `ISR: [N1, N2, N3]` (mismo conjunto, en algún orden). Los líderes están distribuidos: típicamente 2 por broker.

| Pregunta | Respuesta esperada |
|----------|-------------------|
| ISR == Replicas | Sí (clúster sano) |
| MIR del tópico | 2 |
| Productor siguió tras tumbar broker 2 | Sí (gracias a MIR=2 y 2 brokers vivos) |
| ISR cambió | Sí: las réplicas en broker 2 salieron del ISR |
| Particiones que cambiaron líder | Las que tenían a broker 2 como líder (típicamente 2 de 6) |
| Al revivir, broker 2 volvió al ISR | Sí, después del catch-up |
| ¿Recuperó liderazgo? | NO automáticamente. Kafka mantiene el líder actual. Para forzar rebalanceo: `kafka-leader-election --election-type PREFERRED` |

---

## Parte 2: MIR vs ISR

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Estricto con 3 brokers: produjo bien | Sí |
| ISR del estricto tras kill | 2 |
| 2 < 3: ¿bloquea? | Sí |
| Error en estricto | `NotEnoughReplicasException` o timeout |
| ¿Por qué bloquea? | Kafka prioriza durabilidad sobre disponibilidad cuando MIR no se cumple |
| Resiliente con 2 brokers vivos | Funciona porque MIR=2 |
| Estricto al revivir | Vuelve a aceptar escrituras |

### Reflexión

- **MIR=3 con RF=3 nunca tolera ninguna falla**: cualquier mantenimiento bloquea las escrituras. Demasiado estricto.
- **MIR=2 con RF=3** es el balance estándar: tolera 1 falla, mantiene durabilidad de 2/3.
- **Sistema de pagos**: típicamente RF=3, MIR=2, `acks=all`. La app debe manejar `NotEnoughReplicasException` con retry exponencial.

---

## Parte 3: Recuperación

| Pregunta | Respuesta esperada |
|----------|-------------------|
| 5K mensajes con broker caído | Producción ~5-15s, sin problemas |
| Catch-up al revivir | 5-30 segundos según volumen |
| ISR simultáneo | Generalmente sí, pero puede ser de a una en clúster grande |
| Recuperó liderazgo | NO. El nuevo líder se mantiene |
| Total mensajes | Suma de offsets de las 6 particiones (~5000+) |
| Coincide | Sí |
| ¿Por qué no se perdieron? | `acks=all` + MIR=2: las escrituras se confirmaron solo cuando 2 réplicas las recibieron. Al volver, broker 2 las copió del líder |

---

## Parte 4: Retención

### Comportamiento esperado

- **Después de producir y esperar 90s sin más actividad**: probablemente NO hay eliminación. El segmento activo no se cerró porque no hubo nuevos mensajes que fuercen segment.ms.
- **Con producción periódica**: los segments se cierran y se eliminan los más viejos. El offset más antiguo (`--time -2`) sube de 0 a algún número positivo.
- **Diferencia de tamaño**: `efimero` ocupa muy poco (segmentos viejos eliminados). `resiliente` mantiene todo (retención 7 días default).

### Conceptos clave

- Kafka no elimina mensajes individuales; elimina **segmentos completos**.
- `segment.ms` define cuándo se cierra un segmento por tiempo.
- `segment.bytes` lo cierra por tamaño (default 1 GB).
- Solo los segmentos CERRADOS pueden ser eliminados por retention.

---

## Parte 5: Compactación y tombstones

### Comportamiento esperado

| Aspecto | Esperado |
|---------|---------|
| Mensajes producidos en estado | 30 (6 rounds × 5 vehículos) |
| Mensajes leídos tras compactación | Variable: típicamente 5-15 (depende de cuándo se compactó) |
| Claves distintas | 5 (NVT-1 a NVT-5) |
| Vehículo aparece varias veces | Posible: la compactación es asíncrona, no instantánea |

### Tombstone para NVT-3

- Inmediatamente después: NVT-3 con valores anteriores SIGUE apareciendo + el tombstone (NULL_VALUE)
- Después de 60s + nueva compactación: NVT-3 desaparece de la salida (incluyendo el tombstone si pasó `delete.retention.ms`)
- En este lab `delete.retention.ms` es default (24h), así que el tombstone seguirá visible un rato

### Reflexión

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Casos ideales | Estado actual de entidades (perfil de usuario, configuración, último precio, etc.) |
| ¿Por qué KEY obligatorio? | Sin clave no se puede determinar "el último valor" para compactar |
| Mensaje sin clave en compactado | Permanece indefinidamente (la compactación lo ignora) |
| Tombstones con retention propio | Para que consumers lentos puedan ver el "evento de eliminación" antes de que desaparezca |

---

*Solución - Lab 05*
