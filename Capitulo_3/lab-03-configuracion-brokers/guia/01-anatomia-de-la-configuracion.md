# Parte 1: Anatomía de la configuración de un broker

## Objetivo

Entender de dónde sale la configuración efectiva de tu broker: el viaje desde las variables de entorno `KAFKA_*` hasta el `server.properties` que el proceso realmente lee.

## Prerrequisito

Tu clúster de 3 nodos del Lab 02, corriendo.

## Contexto

Este lab tiene una sola idea: **la configuración de tu broker pasa por tres
etapas, y en cada una tiene otra forma.**

```
┌─ 1 · LO QUE ESCRIBES ─────────────────────────────────────────────────┐
│  docker-compose.yml            KAFKA_NODE_ID: 1                       │
└───────────────────────────────────────────────────────────────────────┘
              ↓   la imagen traduce al arrancar
┌─ 2 · LO QUE SE TRADUJO ───────────────────────────────────────────────┐
│  /etc/kafka/kafka.properties   node.id=1                              │
└───────────────────────────────────────────────────────────────────────┘
              ↓   el broker lo carga
┌─ 3 · LO QUE EL BROKER USA ────────────────────────────────────────────┐
│  en memoria, con su origen:    node.id=1  ·  STATIC_BROKER_CONFIG     │
│  STATIC lo escribiste tú  ·  DEFAULT de fábrica  ·  DYNAMIC en vivo   │
└───────────────────────────────────────────────────────────────────────┘
```

**Las etapas 1 y 2 se leen en archivos; la etapa 3 se le pregunta al clúster.**

En la imagen de Confluent no editas `server.properties` a mano: declaras variables `KAFKA_*` en tu compose y la imagen las **traduce** a propiedades al arrancar. La regla del mapeo: quitar el prefijo `KAFKA_`, pasar a minúsculas y cambiar `_` por `.`.

| Variable de entorno | Propiedad resultante |
|---------------------|----------------------|
| `KAFKA_NODE_ID` | `node.id` |
| `KAFKA_PROCESS_ROLES` | `process.roles` |
| `KAFKA_LOG_DIRS` | `log.dirs` |
| `KAFKA_MIN_INSYNC_REPLICAS` | `min.insync.replicas` |

---

## Actividad 1: Encontrar el properties generado

Descubre el archivo que la imagen generó dentro del contenedor:

```bash
docker exec kafka-broker-1 bash -c 'ls /etc/kafka/*.properties'
```

Y examina el que corresponde al broker (el que contiene `process.roles`):

```bash
docker exec kafka-broker-1 bash -c 'grep -E "^(node.id|process.roles|log.dirs|listeners)" /etc/kafka/*.properties'
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué archivo .properties contiene la config del broker? | |
| ¿Qué valor tiene `process.roles` y de qué variable de tu compose salió? | |
| ¿Dónde apunta `log.dirs` y qué variable lo definió? | |

---

## Actividad 2: El mapeo en ambos sentidos

Toma **tres** variables `KAFKA_*` de tu compose y predice la propiedad resultante ANTES de verificarla con `grep` dentro del contenedor. Luego haz el camino inverso: elige una propiedad del properties y reconstruye qué variable la generó.

### Anota

| Variable de tu compose | Propiedad predicha | ¿Coincidió? |
|------------------------|--------------------|-------------|
| | | |
| | | |
| | | |

---

## Siguiente paso

Continúa con [Parte 2: Inspección de la configuración efectiva](02-inspeccion-configuracion-efectiva.md).
