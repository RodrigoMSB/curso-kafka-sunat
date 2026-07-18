# Parte 5: Desafío - Claves y particionado (opcional)

## Objetivo

Verificar empíricamente que **mensajes con la misma clave caen siempre en la misma partición**. Esto es lo que garantiza el orden por entidad en Kafka.

## Contexto

Tu jefe pregunta: *"¿Cómo garantizamos que TODOS los eventos del vehículo NVT-1001 sean procesados en orden, incluso si tenemos 6 particiones repartidas en 3 brokers?"*

Respuesta de Kafka: si produces siempre con `key=NVT-1001`, ese vehículo siempre irá a la misma partición. Como dentro de una partición el orden está garantizado, el orden por vehículo también lo está.

---

## Reto 1: Predicción manual

Antes de producir, calcula con el helper:

```bash
kafka-cli/show-partition-for-key.sh NVT-1001 NVT-1002 NVT-1003 NVT-1004 NVT-1005
```

### Anota

| Vehículo | Partición predicha |
|----------|-------------------|
| NVT-1001 | |
| NVT-1002 | |
| NVT-1003 | |
| NVT-1004 | |
| NVT-1005 | |

> **Nota**: Este script usa `cksum` como aproximación didáctica. Kafka usa `murmur2` internamente, así que las particiones reales pueden diferir.

---

## Reto 2: Verificación empírica con Kafbat UI

Produce 1 mensaje por cada vehículo:

```bash
kafka-cli/produce-event.sh --key NVT-1001 "evento de NVT-1001"
kafka-cli/produce-event.sh --key NVT-1002 "evento de NVT-1002"
kafka-cli/produce-event.sh --key NVT-1003 "evento de NVT-1003"
kafka-cli/produce-event.sh --key NVT-1004 "evento de NVT-1004"
kafka-cli/produce-event.sh --key NVT-1005 "evento de NVT-1005"
```

### Verifica en Kafbat UI

1. Abre **http://localhost:8090**
2. **Topics** > **novatech.fleet.events** > **Messages**
3. Filtra por la columna `Key` y observa la columna `Partition`

### Anota la partición REAL

| Vehículo | Partición real |
|----------|---------------|
| NVT-1001 | |
| NVT-1002 | |
| NVT-1003 | |
| NVT-1004 | |
| NVT-1005 | |

---

## Reto 3: Repetir y verificar consistencia

Produce 3 mensajes adicionales del MISMO vehículo:

```bash
kafka-cli/produce-event.sh --key NVT-1001 "segundo evento de NVT-1001"
kafka-cli/produce-event.sh --key NVT-1001 "tercer evento de NVT-1001"
kafka-cli/produce-event.sh --key NVT-1001 "cuarto evento de NVT-1001"
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 4 eventos de NVT-1001 cayeron todos en la misma partición? | |
| Si sí, ¿qué garantía da esto sobre el orden de procesamiento? | |

---

## Reto 4: Pregunta de reflexión

Si NovaTech tuviera 100 vehículos pero solo 6 particiones, ¿qué pasa?

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cada vehículo tendrá su propia partición? | |
| ¿Habrá colisiones (varios vehículos en una misma partición)? | |
| ¿Eso afecta el orden por vehículo? | |
| ¿Cuántas particiones necesitarías para que cada vehículo tuviera la suya? (suponiendo distribución perfecta) | |

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md` en la sección del desafío.
