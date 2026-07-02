# Lab 01: Inicialización de un clúster KRaft

**Curso**: Administración de Confluent Apache Kafka (SUNAT)
**Unidad**: 2 - Arquitectura y puesta en marcha
**Duración estimada**: ~45 minutos

---

## Contexto narrativo

NovaTech Logistics decidió operar Kafka por su cuenta. Antes de pensar en clústeres productivos, el equipo debe dominar el nacimiento de un broker: qué trae la imagen de Confluent, qué es un cluster-id, por qué el storage se formatea, y cómo se levanta el primer nodo en modo KRaft (sin ZooKeeper).

El CTO te dice:
*"No quiero que nadie opere lo que no sabe encender desde cero. Muéstrame que entiendes cada pieza del arranque: la imagen, el id del clúster, el formateo y el broker corriendo."*

Tu misión: inspeccionar la imagen, generar el cluster-id, formatear el storage y levantar tu primer broker KRaft — construyéndolo tú, pieza por pieza.

---

## ¿Qué vas a aprender?

- Qué trae la imagen `cp-kafka` y cómo se configura por variables de entorno
- Qué es el cluster-id de KRaft y por qué el storage se formatea con él
- Cómo arrancar un broker combinado (broker + controller) desde cero
- Cómo verificar que el storage y el broker quedaron sanos

---

## Estructura

| Guía | Contenido |
|------|-----------|
| `guia/01-anatomia-imagen.md` | La imagen Confluent por dentro |
| `guia/02-mi-primer-broker.md` | Cluster-id, formateo y primer broker (+ desafío) |

Este lab es **construcción propia**: no hay `start-lab.sh`. Tú escribes y levantas tu clúster; `soluciones/` trae la referencia si te atascas, y `bin/90-test-lab.sh` valida tu avance.

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 4 GB |
| Puertos libres | 9092 |
| Otro clúster Kafka detenido | Sí |

---

*Lab 01 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
