# Lab 08: Cambio de configuración de brokers en caliente

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento  
**Duración estimada**: **20 minutos de dictado en clase** (`instructor/GUION.md`)  
~60 minutos si haces el laboratorio completo por tu cuenta, incluida la sección
*Para profundizar* de la guía

---

## Contexto narrativo

NovaTech Logistics entra en temporada alta: el volumen de pedidos se va a duplicar. El equipo de infraestructura necesita **escalar el clúster sin cortar el servicio**: sumar capacidad (un broker nuevo), rebalancear la carga hacia él, y cuando pase el pico, volver a achicar — todo con productores y consumidores corriendo. Además, deben poder **ajustar parámetros del broker en caliente**, sin reiniciar nada.

El CTO te dice:
*"No quiero ventanas de mantenimiento. Si necesito un broker más para el Cyber, lo agrego y rebalanceo en caliente. Si necesito tunear retención o hilos de réplica, lo hago sin reiniciar. Demuéstrame que el clúster aguanta esos cambios sin caerse."*

Tu misión: agregar un cuarto broker a un clúster que está atendiendo y moverle
carga, con productores corriendo — y salir de la operación sabiendo **cómo
deshacerla** y **qué quedó encendido**, que es la parte que casi nadie mira.

---

## ¿Qué vas a aprender?

**En el recorrido de clase:**

- Por qué un broker nuevo entra **vacío**, y por qué agregar capacidad no es lo
  mismo que usarla
- Cómo reasignar particiones con `kafka-reassign-partitions`, en sus tres fases
- 🔴 **El plan de vuelta que imprime el `--execute`**, que es lo único que
  permite deshacer la operación — y que se va con el scroll
- 🔴 **Los throttles que quedan puestos en el clúster**, y por qué un `--verify`
  corrido antes de tiempo los deja ahí para siempre
- Por qué el quórum de controladores no se entera de nada
- Por qué «sin detener nada» no significa «sin que nadie lo note»

**En la sección *Para profundizar* de la guía**, con su comando y su salida real:

- Aplicar el plan de vuelta y comprobar que restituye réplica por réplica
- Ver y limpiar throttles a mano
- Drenar el broker 4 y apagarlo sin perder datos
- La configuración dinámica de brokers — **ya dictada entera en el Lab 03**
- El ciclo completo con tráfico, que es el entregable

---

## Arquitectura del lab

| Nodo | Rol | Estado inicial |
|------|-----|----------------|
| `kafka-broker-1` | broker + controller | Arranca con el lab |
| `kafka-broker-2` | broker + controller | Arranca con el lab |
| `kafka-broker-3` | broker + controller | Arranca con el lab |
| `kafka-broker-4` | **broker-only** | Se agrega en el Paso 2 del recorrido |

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

Luego abre `guia/01-y-quien-mueve-los-datos.md`, y ten a mano `practica/PASOS.md`.

---

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.
>
> **Valida tu avance** en cualquier momento: `bin/90-test-lab.sh`.

*Lab 08 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
