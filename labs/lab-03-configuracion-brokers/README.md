# Lab 03: Configuración de brokers

**Curso**: Administración de Confluent Apache Kafka (SUNAT)
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento
**Duración estimada**: ~40 minutos

---

## Contexto narrativo

El clúster de NovaTech ya corre, pero nadie del equipo sabe explicar de dónde sale cada valor de su configuración. Y lo que no se entiende, no se puede operar.

El CTO te dice:
*"Cuando algo falle a las 3 AM, no quiero adivinanzas. Quiero que sepas exactamente qué configuración está usando cada broker, de dónde salió, y qué se puede cambiar sin reiniciar."*

Tu misión: desarmar la configuración de tu clúster — el viaje de las variables `KAFKA_*` al `server.properties`, y la lectura de la configuración efectiva con sus orígenes.

---

## Prerrequisito encadenado

El clúster de 3 nodos del Lab 02. Si no lo tienes, `soluciones/` del Lab 02 lo reconstruye.

---

## Estructura

| Guía | Contenido |
|------|-----------|
| `guia/01-anatomia-de-la-configuracion.md` | Mapeo `KAFKA_*` env ↔ server.properties |
| `guia/02-inspeccion-configuracion-efectiva.md` | `kafka-configs --describe --all` y orígenes |

---

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.

*Lab 03 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
