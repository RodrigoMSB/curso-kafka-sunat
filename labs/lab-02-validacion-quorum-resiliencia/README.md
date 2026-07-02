# Lab 02: Validación de quórum y resiliencia

**Curso**: Administración de Confluent Apache Kafka (SUNAT)
**Unidad**: 2 - Arquitectura y puesta en marcha
**Duración estimada**: ~45 minutos

---

## Contexto narrativo

Un broker solitario no sobrevive a nada. NovaTech necesita un clúster de verdad: 3 nodos combinados (broker + controller) con quórum KRaft, y la prueba de fuego de que aguanta la caída de un controlador sin perder el control del clúster.

El CTO te dice:
*"Hazlo crecer a tres. Y no me digas que hay quórum: demuéstramelo — apaga un controlador y muéstrame que el clúster sigue mandando."*

Tu misión: extender tu broker del Lab 01 a un clúster de 3 nodos, validar el estado del quórum con las herramientas de metadata, y ejecutar la prueba de resiliencia apagando un controlador.

---

## Prerrequisito encadenado

Este lab **continúa el clúster que construiste en el Lab 01**. Si no lo tienes, usa `soluciones/` del Lab 01 para reconstruirlo rápido.

---

## ¿Qué vas a aprender?

- Cómo crecer de 1 a 3 nodos KRaft (voters, quórum)
- Cómo leer el estado del quórum (`kafka-metadata-quorum`)
- Qué pasa —y qué NO pasa— cuando cae un controlador
- Por qué 3 nodos toleran la caída de exactamente uno

---

## Estructura

| Guía | Contenido |
|------|-----------|
| `guia/01-creciendo-a-tres-brokers.md` | De 1 a 3 nodos con quórum |
| `guia/02-chequeo-salud-y-resiliencia.md` | Salud KRaft + prueba de apagar un controlador |

Construcción propia (sin `start-lab.sh`); `soluciones/` como referencia y `bin/90-test-lab.sh` para validar tu avance.

---

*Lab 02 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
