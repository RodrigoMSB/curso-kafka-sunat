# Lab 03 — Reporte resuelto (solución de referencia)

> Intenta resolver por tu cuenta antes de consultar. Algunos valores pueden variar
> entre ejecuciones; lo importante es la consistencia conceptual.

## Parte 1: Anatomía de la configuración

| Pregunta | Respuesta esperada |
|----------|--------------------|
| ¿Qué archivo .properties contiene la config del broker? | El generado por la imagen bajo `/etc/kafka/` que contiene `process.roles` (típicamente `kafka.properties` o `server.properties` según la versión de la imagen). |
| ¿Qué valor tiene `process.roles` y de qué variable salió? | `broker,controller` (nodo combinado KRaft), generado desde `KAFKA_PROCESS_ROLES`. |
| ¿Dónde apunta `log.dirs` y qué variable lo definió? | Al directorio de datos del broker (p. ej. `/var/lib/kafka/data`), desde `KAFKA_LOG_DIRS`. |

**La regla del mapeo**: quitar el prefijo `KAFKA_`, pasar a minúsculas y cambiar `_` por `.`.
Ejemplos: `KAFKA_NODE_ID` → `node.id`; `KAFKA_PROCESS_ROLES` → `process.roles`;
`KAFKA_MIN_INSYNC_REPLICAS` → `min.insync.replicas`.

## Parte 2: Inspección de la configuración efectiva

| Propiedad | Origen esperado |
|-----------|-----------------|
| `min.insync.replicas` | `STATIC_BROKER_CONFIG` — la declaraste en el compose (`KAFKA_MIN_INSYNC_REPLICAS`). |
| `log.retention.hours` | `DEFAULT_CONFIG` si no la declaraste; `STATIC` si la pusiste en el compose. |
| `num.partitions` | `DEFAULT_CONFIG` salvo que la hayas declarado. |

| Pregunta | Respuesta esperada |
|----------|--------------------|
| ¿Por qué `min.insync.replicas` aparece como STATIC? | Porque vino del `server.properties` generado a partir de tus variables `KAFKA_*` del compose; no es un default de fábrica ni un cambio dinámico. |
| ¿Diferencia práctica STATIC vs DYNAMIC al cambiar un valor? | Cambiar un valor **STATIC** exige reiniciar el broker (está fijado al arranque). Un valor **DYNAMIC** se cambia en caliente vía API, sin reinicio — es lo que harás en el **Lab 08**. |

---

*Solución - Lab 03*
