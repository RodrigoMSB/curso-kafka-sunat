# Parte 2: Inspección de la configuración efectiva

## Objetivo

Leer la configuración **efectiva** de un broker vivo con `kafka-configs`, y distinguir el origen de cada valor: default, estático o dinámico.

## Contexto

El properties dice lo que se declaró; `kafka-configs` dice lo que el broker **realmente está usando**, y de dónde salió cada valor:

| Origen | Significa |
|--------|-----------|
| `DEFAULT_CONFIG` | Nadie lo tocó: valor de fábrica |
| `STATIC_BROKER_CONFIG` | Vino del properties (tus `KAFKA_*`) — cambiarlo exige reinicio |
| `DYNAMIC_BROKER_CONFIG` | Cambiado en caliente vía API (lo harás en el Lab 08) |

---

## Actividad 1: Configuración efectiva del broker 1

```bash
docker exec kafka-broker-1 kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --describe --entity-type brokers --entity-name 1 --all | head -40
```

Busca tres valores concretos:

```bash
docker exec kafka-broker-1 bash -c 'kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --describe --entity-type brokers --entity-name 1 --all | grep -E "min.insync.replicas|log.retention.hours|num.partitions"'
```

### Anota

| Propiedad | Valor efectivo | Origen |
|-----------|----------------|--------|
| `min.insync.replicas` | | |
| `log.retention.hours` | | |
| `num.partitions` | | |

---

## Actividad 2: Predicción de origen

Antes de mirar, predice: ¿qué origen tendrá una propiedad que declaraste en tu compose vs una que nunca mencionaste? Verifica con dos ejemplos de cada tipo.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué `min.insync.replicas` aparece como STATIC en tu clúster? | |
| ¿Qué diferencia práctica hay entre STATIC y DYNAMIC a la hora de cambiar un valor? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Mapeo env → properties | Predijiste y verificaste la traducción de `KAFKA_*` |
| Configuración efectiva | Leíste lo que el broker usa de verdad, no lo que crees |
| Orígenes de configuración | Distinguiste DEFAULT / STATIC / DYNAMIC |

> En el **Lab 08** cerrarás el círculo: cambiarás configuración DYNAMIC en caliente, sin reiniciar.
