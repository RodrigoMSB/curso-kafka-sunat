# Lab 02 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1-3: Particionado por clave

### Comportamiento esperado

1. **Predicción con cksum vs realidad murmur2**: las particiones específicas pueden diferir entre la predicción del script y lo que aparece en Kafbat UI. Esto es normal: `cksum` es una aproximación didáctica.

2. **Consistencia interna**: lo crítico es que CADA clave siempre vaya a la MISMA partición:
   - Si NVT-1001 cayó en la partición 3, los 4 eventos de NVT-1001 estarán en la partición 3.
   - Si NVT-1002 cayó en la partición 5, todos sus eventos estarán en la 5.

3. **Verificación visual en Kafbat UI**:
   - **Topics** > **novatech.fleet.events** > **Messages**
   - Filtrar mensajes por columna `Key`
   - Confirmar que `Partition` es siempre el mismo para una clave dada

---

## Reto 4: Reflexión sobre 100 vehículos en 6 particiones

### Distribución

Con 100 claves distribuidas uniformemente en 6 particiones (asumiendo buen hash):
- Promedio: ~17 vehículos por partición
- Cada vehículo comparte su partición con ~16 otros vehículos

### Implicaciones del orden

**El orden por vehículo se mantiene**:
- Dentro de una partición, los mensajes están en orden cronológico de llegada
- Si NVT-1001 envía sus eventos en orden A, B, C, todos llegan a la misma partición y en ese orden
- Aunque NVT-1042 también esté en esa partición, sus eventos no rompen el orden de NVT-1001 (Kafka mantiene el orden de inserción)

**El orden global NO se mantiene**:
- Si NVT-1001 emite un evento A en partición 3, y NVT-1002 emite un evento B en partición 5, no podemos garantizar que A se procese antes que B desde la perspectiva del consumidor multi-partición

### Cuándo importa cuántas particiones

Para garantizar **una partición por entidad** (raro y normalmente innecesario):
- Necesitarías al menos N particiones para N entidades, asumiendo distribución perfecta del hash
- En la práctica, debido a colisiones de hash, se recomienda 2-3x el número de entidades únicas
- **Esto casi nunca se hace**. Las colisiones de hash son aceptables porque el orden se garantiza POR clave, no por entidad única en partición única

---

*Soluciones del desafío - Lab 02*
