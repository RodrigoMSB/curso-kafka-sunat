# Lab 05 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1-2: Compactación

La compactación es asíncrona. Aún con `min.cleanable.dirty.ratio=0.01`, depende de:
- Que el log cleaner thread se active
- Que haya al menos 1 segmento "viejo" (no el activo)
- Que el ratio de dirty/total supere el umbral

En el lab, después de 30 mensajes y unos 30s, lo más probable es que el alumno vea **menos de 30 pero más de 5**, porque algunas claves duplicadas todavía no se compactaron.

## Reto 3: Tombstones

### Mecánica detallada

1. **Producir tombstone**: Kafka acepta un mensaje con `value=null` para una clave existente.
2. **Antes de compactación**: el tombstone aparece como un mensaje más en el log (con valor null).
3. **Durante compactación**: Kafka identifica que la clave tiene un tombstone como último valor → marca para eliminación.
4. **Resultado**:
   - Todos los mensajes anteriores de esa clave se borran.
   - El tombstone permanece visible durante `delete.retention.ms` (default 24h).
   - Después, también se borra.

### Verificación visual

En Kafbat UI > Topics > `novatech.lab05.estado` > Messages:
- Antes del tombstone: ves múltiples mensajes con clave NVT-3.
- Después del tombstone (sin compactación): ves los anteriores + el tombstone (valor null).
- Después de compactación: solo ves el tombstone (los anteriores desaparecieron).
- Después de 24h: ya no ves nada de NVT-3.

## Reto 4: Reflexión

### Casos de uso ideales para compactación

- **Estado de entidades**: último estado conocido por ID
- **Configuraciones por aplicación**: última versión de la config
- **Cache materializado**: para reconstruir cache desde Kafka al iniciar una app
- **Cambio de propiedad**: último dueño de un recurso

### Casos NO ideales

- **Eventos**: cada evento es único, no quieres que se "compacte" sobre eventos previos
- **Logs de auditoría**: necesitas el historial completo, no solo el último

### Por qué KEY es obligatorio

La compactación se basa en agrupar por clave. Sin clave, no hay agrupación posible. Kafka simplemente IGNORA mensajes sin clave en tópicos compactados (los deja indefinidamente).

### Tombstones con retention propio

Imagina un consumer que estuvo offline 1 hora. Cuando vuelve, necesita saber que NVT-3 fue eliminado para limpiar su cache local. Si el tombstone se borrara inmediatamente, el consumer nunca se enteraría. `delete.retention.ms` (24h por default) le da una ventana.

---

*Soluciones del desafío - Lab 05*
