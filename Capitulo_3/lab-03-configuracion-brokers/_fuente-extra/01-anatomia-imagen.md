# Parte 1: Anatomía de la imagen Confluent

## Objetivo

Antes de configurar nada, explorar **qué viene dentro** de la imagen oficial `confluentinc/cp-kafka:8.2.0`. Conocer las herramientas que tendrás a tu disposición.

## Contexto

Hasta ahora usaste el clúster como caja negra: `docker compose up` y todo funcionaba. Para **administrar** Kafka, necesitas saber qué hay dentro de la caja.

---

## Actividad 1: Inspeccionar la imagen

Ejecuta:

```bash
kafka-cli/inspect-image.sh
```

Este script:
1. Hace pull de la imagen `confluentinc/cp-kafka:8.2.0`
2. Lista los binarios CLI de Kafka en `/usr/bin/`
3. Lista los archivos de configuración de ejemplo en `/etc/kafka/`
4. Muestra la versión de Java embebida

### Anota tus observaciones

| Observación | Tu respuesta |
|------|-------------|
| ¿Cuántos binarios `kafka-*` aparecen? | |
| Lista 5 que te llamen la atención | |
| ¿Qué archivos hay en `/etc/kafka/`? | |
| ¿Qué versión de Java trae? | |

---

## Actividad 2: Explorar el server.properties de ejemplo

```bash
docker run --rm confluentinc/cp-kafka:8.2.0 cat /etc/kafka/server.properties | head -50
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué `process.roles` están definidos por defecto? | |
| ¿En qué puerto escucha por defecto? | |
| ¿Dónde guarda los logs? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Estructura de imagen Confluent | Listaste binarios y archivos de configuración |
| Defaults de Kafka KRaft | Inspeccionaste el server.properties de ejemplo |

---

## Siguiente paso

Continúa con la [Parte 2: Mi primer broker solitario](02-mi-primer-broker.md).
