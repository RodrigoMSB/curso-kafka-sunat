# Lab 04: Clúster multi-broker y advertised.listeners

**Curso**: Administración de Confluent Apache Kafka (SUNAT)
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento
**Duración estimada**: ~40 minutos

---

## Contexto narrativo

El clúster de NovaTech corre puertas adentro, pero los clientes reales viven fuera de la red de Docker. Exponerlo mal es el error de configuración más clásico de Kafka: el bootstrap conecta, y al primer metadata el cliente muere porque el broker publicó una dirección que nadie de afuera puede alcanzar.

El CTO te dice:
*"Nuestros productores no van a correr dentro del contenedor. Sepáralo bien: un listener para los brokers, otro para el quórum, otro para los clientes de afuera. Y pruébame desde fuera que funciona — no me sirve que 'conecte' y luego se caiga."*

Tu misión: entender y separar los listeners (PLAINTEXT / CONTROLLER / EXTERNAL) de tu clúster de 3 nodos, y verificar desde fuera de la red que `advertised.listeners` publica direcciones realmente alcanzables.

---

## Prerrequisito encadenado

El clúster de 3 nodos del Lab 02. Si no lo tienes, `soluciones/` del Lab 02 lo reconstruye.

---

## ¿Qué vas a aprender?

- Por qué un broker KRaft necesita listeners separados (interno, controlador, externo)
- Qué es `advertised.listeners` y en qué se diferencia de `listeners`
- Cómo verificar desde FUERA de la red que el listener EXTERNAL es alcanzable
- El fallo clásico: bootstrap OK + metadata con dirección inalcanzable = cliente muerto

---

## Estructura

| Guía | Contenido |
|------|-----------|
| `guia/01-listeners-separados.md` | Listeners PLAINTEXT / CONTROLLER / EXTERNAL |
| `guia/02-verificacion-externa.md` | Prueba del cliente externo + romperlo a propósito |

Construcción propia (sin `start-lab.sh`); `soluciones/` como referencia y `bin/90-test-lab.sh` para validar tu avance.

---

*Lab 04 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
