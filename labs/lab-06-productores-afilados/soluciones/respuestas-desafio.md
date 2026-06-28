# Lab 06 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1: Particionado por clave fija

### Comportamiento

Cuando produces 50.000 mensajes con la MISMA clave (`K`), todos van a la misma partición porque `partition = hash(key) % num_partitions`. Verificable con:

```bash
kafka-cli/describe-topic.sh novatech.tuning.bench
```

Verás que solo una partición tiene `End Offset` alto; las demás siguen igual.

### Throughput

Con clave fija: típicamente **30-50% del throughput** comparado con distribución uniforme. Razón: un solo broker líder hace todo el trabajo de esa partición; los demás están ociosos.

---

## Reto 2: RoundRobinPartitioner vs Default

### Default (sticky)

El particionador default desde Kafka 3.x (vigente en 4.x) usa **sticky batching**: agrupa mensajes en batches por partición, cambiando de partición solo cuando el batch se cierra. Esto da mejor throughput y mejor compactación de batches.

### RoundRobinPartitioner

Distribuye estrictamente uno por uno entre particiones. Resultado: batches más pequeños, peor agrupación, **peor throughput** (a veces 20-40% menor).

### Cuándo usar cada uno

- **Default (sticky)**: 99% de los casos. Mejor throughput.
- **RoundRobinPartitioner**: cuando necesitas distribución estrictamente uniforme y no te importa el throughput.

---

## Reto 3: Reflexión final

### Hot partitioning con 6 VIPs

Si NVT-VIP-1 a NVT-VIP-6 generan el 80% del tráfico, y el hash los pone en distintas particiones, esas 6 particiones quedan saturadas mientras las demás están ociosas.

**Soluciones**:

1. **Particionador custom**: detecta claves "VIP" y las distribuye uniformemente ignorando el hash.
2. **Cambiar el schema de claves**: concatenar `VIP_ID + bucket(timestamp, 10)` para distribuir cada VIP en 10 sub-claves.
3. **Tópico separado para VIPs**: aislar el tráfico de alta carga en su propio tópico con más particiones.

### Hot partitioning con vehículos comunes

Si tienes 5000 vehículos con tráfico parejo, el hash distribuye uniformemente y no hay problema. El issue solo aparece cuando hay **skew** en la generación de tráfico.

### Cuándo no importa el orden por clave

- **Métricas agregadas**: contar eventos totales por minuto. El orden de llegada de eventos individuales no afecta la suma.
- **Logs de aplicación**: cada evento es independiente; el orden ayuda al debugger pero no es estricto.
- **Procesamiento por batch**: si procesas cada hora todos los eventos del último minuto, el orden dentro del batch no afecta el resultado.
- **Eventos con timestamp**: si el receptor reordena por timestamp, no necesitas que Kafka lo mantenga.

### Cuándo SÍ importa el orden por clave

- **Estado de entidades**: actualizar el estado de un vehículo (MOVING → STOPPED → MAINTENANCE). Si llegan en otro orden, el estado final puede ser incorrecto.
- **Pagos / saldos**: depósitos y retiros que afectan un saldo. El orden importa.
- **Eventos de máquinas de estado**: cualquier sistema con transiciones que dependen del estado anterior.

---

*Soluciones del desafío - Lab 06*
