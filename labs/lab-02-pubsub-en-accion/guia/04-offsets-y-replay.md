# Parte 4: Offsets y replay (viajar en el tiempo)

## Objetivo

Entender cómo cada consumer group mantiene **su propia posición de lectura (offsets)**, y cómo se puede manipular para "rebobinar" y reprocesar mensajes.

## Contexto

El **Módulo de Reportes Históricos** de NovaTech necesita re-procesar todos los eventos del día para generar un análisis estadístico. Pero el grupo de alertas ya leyó esos mensajes hace horas. ¿Cómo le decimos a Reportes que vuelva al inicio sin afectar al resto?

Respuesta: cada consumer group tiene **sus propios offsets**, independientes de los demás.

---

## Actividad 1: Ver offsets actuales

Antes de empezar, asegúrate de que el grupo `alertas` tenga consumidores cerrados (Ctrl+C en cualquier terminal del Lab anterior).

Ejecuta:

```bash
kafka-cli/describe-group.sh alertas
```

### Anota

| Partición | CURRENT-OFFSET | LOG-END-OFFSET | LAG |
|-----------|----------------|----------------|-----|
| 0 | | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

> **Lag** = mensajes pendientes de leer = `LOG-END-OFFSET - CURRENT-OFFSET`

---

## Actividad 2: Crear un grupo nuevo desde cero

Vamos a simular el módulo de **Reportes Históricos**, que quiere leer TODO el histórico.

Lanza un consumidor con un grupo nuevo:

```bash
kafka-cli/consume-as-group.sh --group reportes
```

Inmediatamente espera ver muchos mensajes (todos los que has producido en este lab).

Cuando hayan dejado de llegar, presiona Ctrl+C.

Verifica:

```bash
kafka-cli/describe-group.sh reportes
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿`reportes` recibió mensajes históricos o solo nuevos? | |
| ¿Por qué? | |

> **Pista**: cuando un grupo se crea por primera vez, el comportamiento por defecto puede variar. Verifica si `reportes` empezó desde el inicio o desde el final.

---

## Actividad 3: Reset de offsets - "rebobinar"

Imagina que el módulo de Reportes tuvo un bug y necesita re-procesar todo. Vamos a resetear sus offsets.

**Paso 1**: asegúrate de que NO haya consumidores activos en el grupo `reportes` (Ctrl+C en la terminal de la actividad 2).

> **⚠ Nota operacional importante**: tras presionar Ctrl+C en un consumer, su sesión queda activa en el broker durante **~45-60 segundos** (es el `session.timeout.ms` default). Si intentás resetear el consumer group antes de ese tiempo, vas a ver:
>
> ```
> Error: Assignments can only be reset if the group 'reportes' is inactive,
> but the current state is Stable.
> ```
>
> Soluciones, en orden de preferencia:
> - **(a)** Esperar 60 segundos tras Ctrl+C antes de ejecutar el reset.
> - **(b)** Ejecutar `bin/reset-lab.sh` para empezar el lab desde cero (es la opción más limpia si querés re-experimentar varias veces).

**Paso 2**: ejecuta el reset:

```bash
kafka-cli/reset-group.sh reportes
```

**Paso 3**: verifica:

```bash
kafka-cli/describe-group.sh reportes
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál es el nuevo CURRENT-OFFSET de cada partición? | |
| ¿Cuál es el LAG ahora? | |

---

## Actividad 4: Re-procesar el histórico

Ahora lanza nuevamente el consumidor:

```bash
kafka-cli/consume-as-group.sh --group reportes
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Recibiste TODOS los mensajes desde el inicio? | |
| ¿El grupo `alertas` se vio afectado por este reset? (Verifícalo con `describe-group.sh alertas`) | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Offsets por grupo | Cada grupo tiene su propia posición |
| Lag | Diferencia entre lo escrito y lo leído |
| Reset | Manipulaste los offsets para rebobinar |
| Aislamiento | Resetear un grupo NO afectó a otros |

---

## Siguiente paso

Continúa con la [Parte 5: Desafío de claves y particionado](05-desafio-keys-y-particionado.md).
