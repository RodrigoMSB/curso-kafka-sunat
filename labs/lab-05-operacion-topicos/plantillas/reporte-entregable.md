# Reporte del Lab 05: Operación de tópicos

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Anatomía de un tópico

| Pregunta | Tu respuesta |
|----------|-------------|
| Tópicos visibles sin `--internal` | |
| Tópicos visibles con `--internal` | |
| Tópicos internos detectados | |
| ¿Para qué sirve `__consumer_offsets`? | |

### Estructura de `novatech.fleet.gps`

| Atributo | Valor |
|----------|-------|
| Particiones | |
| Replication factor | |
| Líder de partición 0 | |
| ISR de partición 0 | |
| ¿Réplicas Out-of-Sync? | |

### 5 configuraciones efectivas observadas

| Config | Valor | ConfigSource |
|--------|-------|--------------|
| | | |
| | | |
| | | |
| | | |
| | | |

---

## Parte 2: Tópicos con personalidad

### `novatech.gps.realtime`

| Atributo | Valor |
|----------|-------|
| Particiones | |
| `retention.ms` efectivo | |
| `compression.type` efectivo | |
| ¿Por qué 12 particiones y no 6? | |

### `novatech.audit.events`

| Atributo | Valor |
|----------|-------|
| `retention.ms` efectivo | |
| ¿Por qué `gzip`? | |
| ¿Qué pasa si solo 1 réplica está sincronizada y `min.insync.replicas=2`? | |

### `novatech.vehicle.state`

| Atributo | Valor |
|----------|-------|
| `cleanup.policy` efectivo | |
| ¿Qué hace `min.cleanable.dirty.ratio=0.1`? | |
| Después de 100 mensajes con `key=NVT-1001`, ¿cuántos quedan? | |
| ¿Cuántos mensajes consumiste justo después? | |

### `novatech.alerts.critical`

| Atributo | Valor |
|----------|-------|
| ¿Se puede escribir si un broker se cae? | |
| ¿Qué hace `unclean.leader.election.enable=false`? | |
| ¿Qué se sacrifica con `min.insync.replicas=3`? | |

---

## Parte 3: Modificar tópicos en caliente

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió `retention.ms` después de `--alter`? | |
| ¿`ConfigSource` cambió a `DYNAMIC_TOPIC_CONFIG`? | |
| ¿Particiones después de aumentar (12 → ?) | |
| ¿Las nuevas particiones (12-17) tienen mensajes? | |
| ¿Qué error al intentar disminuir particiones? | |
| ¿Por qué Kafka no permite disminuir? | |
| ¿Qué `retention.ms` quedó después de `--delete`? | |

---

## Parte 4: Retención por tiempo en vivo

| Pregunta | Tu respuesta |
|----------|-------------|
| Offset más antiguo disponible tras esperar (`--time -2`) | |
| ¿Se eliminaron mensajes viejos? ¿Por qué `segment.ms` corto importa? | |
| Tamaño en disco de `efimero` vs `resiliente` (Kafbat UI) | |
| ¿Por qué Kafka borra por segmentos completos y no mensaje a mensaje? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre administración de tópicos:

```


```

---

*Lab 05 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
