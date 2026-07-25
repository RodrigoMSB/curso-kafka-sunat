# Parte 1: Tipos de configuración del broker

## Objetivo

Distinguir los tres tipos de configuración de un broker Kafka y saber cuáles se pueden cambiar en caliente.

## Contexto

No toda configuración de Kafka se cambia igual. Algunas exigen reiniciar el broker; otras se aplican al instante. Saber cuál es cuál es la diferencia entre una ventana de mantenimiento y un cambio transparente.

| Tipo | ¿Reinicio? | Alcance | Ejemplo |
|------|-----------|---------|---------|
| **read-only** | Sí | Fijada al arranque | `process.roles`, `log.dirs`, `node.id` |
| **per-broker** (dinámica) | No | Un broker específico | `num.replica.fetchers`, `log.cleaner.threads` |
| **cluster-wide** (dinámica) | No | Default para todos los brokers | `log.retention.ms`, `message.max.bytes` |

---

## Actividad 1: Configuración efectiva de un broker

Mira la configuración activa del broker 1:

```bash
kafka-cli/describe-broker-config.sh 1
```

Verás una lista larga. Cada línea indica el valor y su **origen** (`sensitive`, `DEFAULT_CONFIG`, `STATIC_BROKER_CONFIG`, `DYNAMIC_BROKER_CONFIG`, etc.).

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué valor tiene `num.replica.fetchers`? | |
| ¿Qué origen muestra (`DEFAULT_CONFIG`, `STATIC...`)? | |

---

## Actividad 2: Configuración por defecto del clúster

Ahora mira los defaults dinámicos a nivel de clúster:

```bash
kafka-cli/describe-broker-config.sh default
```

Al inicio probablemente esté vacío o casi: aún no se ha fijado ningún default dinámico cluster-wide. Eso cambiará en la guía 02.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué la configuración `default` aparece vacía al inicio? | |
| ¿Qué diferencia hay entre un default cluster-wide y un valor per-broker? | |

---

## Siguiente paso

Continúa con [Parte 2: Reconfiguración en caliente](02-reconfiguracion-en-caliente.md).
