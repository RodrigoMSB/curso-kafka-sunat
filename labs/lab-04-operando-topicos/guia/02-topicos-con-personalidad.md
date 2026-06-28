# Parte 2: Tópicos con personalidad

## Objetivo

Crear 4 tópicos con configuraciones específicas, cada uno adaptado a un caso de uso real de NovaTech. Verificar que las configs efectivamente quedan aplicadas.

## Contexto

El CTO de NovaTech te dio el siguiente brief. Cada tipo de dato necesita su propio perfil:

| Tópico | Caso de uso | Config crítica |
|--------|------------|----------------|
| `novatech.gps.realtime` | Telemetría alta frecuencia | Retención 1 hora, compresión `lz4` |
| `novatech.audit.events` | Compliance y auditoría | Retención 90 días, sin compactación |
| `novatech.vehicle.state` | Estado actual por vehículo | **Compactación** (no retención por tiempo) |
| `novatech.alerts.critical` | Alertas críticas | `min.insync.replicas=3`, retención ilimitada |

---

## Actividad 1: Tópico de alta frecuencia

```bash
kafka-cli/create-topic.sh novatech.gps.realtime \
    --partitions 12 \
    --rf 3 \
    --config retention.ms=3600000 \
    --config compression.type=lz4 \
    --config segment.ms=600000
```

> **3.600.000 ms** = 1 hora. **600.000 ms** = 10 min de segmento.

### Verificación

```bash
kafka-cli/describe-topic.sh novatech.gps.realtime
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene? | |
| `retention.ms` efectivo | |
| `compression.type` efectivo | |
| ¿Por qué 12 particiones y no 6? | |

---

## Actividad 2: Tópico de compliance (auditoría)

```bash
kafka-cli/create-topic.sh novatech.audit.events \
    --partitions 6 \
    --rf 3 \
    --config retention.ms=7776000000 \
    --config compression.type=gzip \
    --config min.insync.replicas=2
```

> **7.776.000.000 ms** = 90 días. `gzip` comprime más que `lz4` pero usa más CPU (justificado para datos que se acceden poco).

| Pregunta | Tu respuesta |
|----------|-------------|
| `retention.ms` efectivo | |
| ¿Por qué `gzip` aquí en vez de `lz4`? | |
| ¿Qué pasa si solo 1 réplica está sincronizada y `min.insync.replicas=2`? | |

---

## Actividad 3: Tópico compactado (estado actual)

Este es **conceptualmente distinto**: en vez de retener por tiempo, el log mantiene **solo el último mensaje por clave**.

```bash
kafka-cli/create-topic.sh novatech.vehicle.state \
    --partitions 6 \
    --rf 3 \
    --config cleanup.policy=compact \
    --config min.cleanable.dirty.ratio=0.1
```

| Pregunta | Tu respuesta |
|----------|-------------|
| `cleanup.policy` efectivo | |
| ¿Qué hace `min.cleanable.dirty.ratio=0.1`? | |
| Si publicas 100 mensajes con `key=NVT-1001`, ¿cuántos quedarán al final? | |

### Probarlo

Produce 5 mensajes para el mismo vehículo (todos con clave `NVT-1001`):

```bash
for i in 1 2 3 4 5; do
    echo "NVT-1001:estado_v${i}" | docker exec -i $(docker ps --filter "name=kafka-broker-1" --format "{{.Names}}") \
        kafka-console-producer --bootstrap-server kafka-broker-1:29092 \
        --topic novatech.vehicle.state \
        --property "parse.key=true" --property "key.separator=:"
done
```

Espera unos segundos y consume:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.vehicle.state \
    --from-beginning --max-messages 10 \
    --property "print.key=true" --property "key.separator=:" \
    --timeout-ms 5000
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes ves al consumir? | |
| ¿Por qué? (la compactación puede tardar; algunos pueden todavía estar) | |

> **Nota**: La compactación es asíncrona. Inmediatamente después de producir, todos los mensajes están ahí. Kafka los compacta en background. En producción esto puede tomar minutos u horas según el ratio dirty.

---

## Actividad 4: Tópico de alta confiabilidad

```bash
kafka-cli/create-topic.sh novatech.alerts.critical \
    --partitions 3 \
    --rf 3 \
    --config min.insync.replicas=3 \
    --config retention.ms=-1 \
    --config unclean.leader.election.enable=false
```

> `retention.ms=-1` = retención ilimitada. `min.insync.replicas=3` = los 3 brokers DEBEN confirmar cada escritura.

| Pregunta | Tu respuesta |
|----------|-------------|
| Si un broker se cae, ¿se pueden seguir escribiendo mensajes en este tópico? | |
| ¿Por qué `unclean.leader.election.enable=false`? | |
| ¿Qué se sacrifica al exigir `min.insync.replicas=3`? | |

---

## Actividad 5: Resumen visual

Lista todos los tópicos:
```bash
kafka-cli/list-topics.sh
```

Y verifica cada uno en Kafbat UI > Topics. Compara las 4 configuraciones distintas.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| `retention.ms` | Configuraste 1h, 90 días e ilimitado |
| `cleanup.policy=compact` | Probaste con el tópico de estado |
| `min.insync.replicas` | Lo subiste a 3 para alertas críticas |
| `compression.type` | Comparaste `lz4` (rápido) vs `gzip` (denso) |
| Particionado | Diferenciaste 3, 6 y 12 particiones según el caso |

---

## Siguiente paso

Continúa con [Parte 3: Modificar tópicos en caliente](03-modificar-topicos-en-caliente.md).
