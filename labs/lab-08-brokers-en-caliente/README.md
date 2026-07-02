# Lab 08: Cambio de configuración de brokers en caliente

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento  
**Duración estimada**: ~60 minutos

---

## Contexto narrativo

NovaTech Logistics entra en temporada alta: el volumen de pedidos se va a duplicar. El equipo de infraestructura necesita **escalar el clúster sin cortar el servicio**: sumar capacidad (un broker nuevo), rebalancear la carga hacia él, y cuando pase el pico, volver a achicar — todo con productores y consumidores corriendo. Además, deben poder **ajustar parámetros del broker en caliente**, sin reiniciar nada.

El CTO te dice:
*"No quiero ventanas de mantenimiento. Si necesito un broker más para el Cyber, lo agrego y rebalanceo en caliente. Si necesito tunear retención o hilos de réplica, lo hago sin reiniciar. Demuéstrame que el clúster aguanta esos cambios sin caerse."*

Tu misión: clasificar los tipos de configuración del broker, aplicar cambios dinámicos en vivo, agregar un broker y reasignar particiones hacia él, y drenarlo para quitarlo — verificando en cada paso la continuidad del servicio.

---

## ¿Qué vas a aprender?

- Los tipos de configuración del broker: read-only, dinámica por-broker y dinámica cluster-wide
- Cómo aplicar reconfiguraciones en caliente con `kafka-configs`, sin reiniciar
- Cómo agregar un broker a un clúster en marcha
- Cómo reasignar particiones con `kafka-reassign-partitions` para rebalancear la carga
- Cómo drenar y quitar un broker sin perder datos
- Por qué el quórum de controladores se mantiene fijo mientras los brokers escalan

---

## Arquitectura del lab

| Nodo | Rol | Estado inicial |
|------|-----|----------------|
| `kafka-broker-1` | broker + controller | Arranca con el lab |
| `kafka-broker-2` | broker + controller | Arranca con el lab |
| `kafka-broker-3` | broker + controller | Arranca con el lab |
| `kafka-broker-4` | **broker-only** | Se agrega en la guía 03 |

Los 3 primeros forman el quórum de controladores (fijo). El broker-4 entra y sale como capacidad de cómputo sin tocar el quórum.

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 8 GB (4 brokers en el pico) |
| Disco libre | 10 GB |
| Puertos libres | 9092, 9093, 9094, 9095, 8090 |
| Otro clúster Kafka detenido | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

Arranca 3 brokers + Kafbat UI, crea el tópico `novatech.lab08.pedidos` (6 particiones, RF 3) y produce 5.000 mensajes de muestra.

Luego abre `guia/01-tipos-de-configuracion.md`.

---

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.
>
> **Valida tu avance** en cualquier momento: `bin/90-test-lab.sh`.

*Lab 08 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
