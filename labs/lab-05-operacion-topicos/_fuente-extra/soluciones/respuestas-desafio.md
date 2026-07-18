# Lab 04 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1: Eliminar tópico

- Eliminación lógica: inmediata (el tópico desaparece de `--list`)
- Eliminación física: depende de `delete.topic.enable=true` (default en Kafka 4.x) y del cleanup interno (segundos a minutos)
- Si el tópico tenía consumer groups activos, esos grupos quedan con offsets huérfanos

## Reto 2: Aumentar RF con plan de reasignación

El plan JSON especifica explícitamente qué brokers tendrán cada partición. Ejemplo de salida tras `--verify`:

```
Status of partition reassignment:
Reassignment of partition novatech.test.rf1-0 is completed.
Reassignment of partition novatech.test.rf1-1 is completed.
Reassignment of partition novatech.test.rf1-2 is completed.
```

Después del cambio, `describe-topic.sh` muestra:
```
Topic: novatech.test.rf1
PartitionCount: 3
ReplicationFactor: 3
Topic: novatech.test.rf1 Partition: 0 Leader: 1 Replicas: 1,2,3 Isr: 1,2,3
...
```

### ¿Por qué requiere plan explícito?

- Cambiar RF implica COPIAR datos físicos entre brokers
- El admin debe controlar:
  - **Cuándo** ocurre (ventana de mantenimiento)
  - **A qué brokers** se mueve (no saturar uno)
  - **Throttling**: `--throttle <bytes/sec>` para no afectar producción
- `kafka-topics --alter` no tiene esta capacidad de control

## Reto 3: Reflexión

### ¿Más peligroso: particiones o RF?

**RF es más peligroso operacionalmente**:
- Aumentar particiones: cambia hash routing pero no mueve datos antiguos. Es CPU/coordinación.
- Aumentar RF: copia físicamente todos los datos del tópico a más brokers. Genera tráfico masivo de replicación. Puede saturar la red interna y afectar la latencia de producción.

### Rollback de retention

- Aplicar `--alter` con el valor anterior. **Pero**: los mensajes que ya se eliminaron por la retention nueva NO vuelven.
- Por eso se recomienda: ANTES de bajar retention, exportar/respaldar lo crítico.

### `min.insync.replicas` para pagos

**Recomendación: `min.insync.replicas=2` con RF=3**

Razones:
- Tolerancia a 1 falla simultánea (broker caído por mantenimiento)
- Si exiges 3, cualquier mantenimiento bloquea las escrituras
- 2/3 es el balance estándar entre durabilidad y disponibilidad
- Las apps deben manejar `NotEnoughReplicasException` con retry

---

*Soluciones del desafío - Lab 04*
