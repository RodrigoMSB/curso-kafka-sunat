# Parte 2: Reconfiguración en caliente

## Objetivo

Aplicar cambios de configuración dinámica —per-broker y cluster-wide— sin reiniciar ningún broker, y verificar que toman efecto.

## Contexto

NovaTech necesita subir la paralelización de réplica en un broker que va lento, y bajar la retención por defecto del clúster para ahorrar disco — sin parar el servicio.

---

## Actividad 1: Cambio per-broker (dinámico)

Sube los hilos de fetch de réplica solo en el broker 1:

```bash
kafka-cli/alter-broker-config.sh 1 num.replica.fetchers=4
```

Verifica que se aplicó (sin reinicio):

```bash
kafka-cli/describe-broker-config.sh 1
```

Busca `num.replica.fetchers=4` con origen `DYNAMIC_BROKER_CONFIG`.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El broker se reinició? (revisa `docker ps`, columna de uptime) | |
| ¿Qué origen muestra ahora `num.replica.fetchers`? | |

---

## Actividad 2: Cambio cluster-wide (dinámico)

Baja la retención por defecto de todos los brokers a 1 hora:

```bash
kafka-cli/alter-broker-config.sh default log.retention.ms=3600000
```

Verifica:

```bash
kafka-cli/describe-broker-config.sh default
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece `log.retention.ms=3600000` en la config default? | |
| ¿A cuántos brokers afecta este cambio? | |

---

## Actividad 3: Lo que NO se puede cambiar en caliente

Intenta cambiar una propiedad read-only (rol del proceso):

```bash
kafka-cli/alter-broker-config.sh 1 process.roles=broker
```

Esto **debe fallar** o ser rechazado: `process.roles` es read-only, fijada al arranque.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué mensaje de error te dio Kafka? | |
| ¿Por qué tiene sentido que esta propiedad sea read-only? | |

---

## Siguiente paso

Continúa con [Parte 3: Agregar un broker y reasignar](03-agregar-broker-y-reasignar.md).
