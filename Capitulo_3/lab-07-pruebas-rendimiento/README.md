# Lab 07: Pruebas de rendimiento

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento  
**Duración estimada**: **20 minutos de dictado en clase** (`instructor/GUION.md`)  
~60 minutos si haces el laboratorio completo por tu cuenta, incluida la sección
*Para profundizar* de la guía

---

## Contexto narrativo

El equipo de infraestructura de NovaTech necesita dimensionar el clúster antes de la temporada alta:

*"Necesito saber cuánto throughput aguanta el clúster produciendo y consumiendo, cuál es la latencia, y qué parámetros mover para exprimirlo. Mídelo en serio, con números."*

Tu misión: medir el rendimiento con las herramientas de perf-test y decidir, con
los números en la mano, **si un cambio de tuning se puede afirmar o no**. Spoiler
del recorrido: con el parámetro que vamos a mover, la respuesta medida es que
**no se distingue** — y aprender a reportar eso es el laboratorio.

---

## ¿Qué vas a aprender?

**En el recorrido de clase:**

- Cuánto se mueve una medición de rendimiento **cuando no cambias nada**, y por
  qué eso hay que medirlo antes de tunear
- Medir throughput y latencia con `kafka-producer-perf-test`
- Por qué una mejora **solo cuenta si es más grande que ese ruido**, y por qué
  ganar tres comparaciones de tres puede no ser evidencia de nada
- Cómo se reporta un **«no se distingue»** sin que suene a trabajo no hecho
- Por qué el rendimiento se vigila en percentiles y no en promedios
- Por qué se mueve **un parámetro a la vez**

**En la sección *Para profundizar* de la guía**, con su comando y su salida real:

- Los tres niveles de `acks`, medidos — el recorrido los explica sin
  ejecutarlos, y aquí están las nueve corridas que muestran por qué en este
  clúster no se distinguen
- `batch.size`, el único parámetro del lab cuyo efecto **sí** sobrevive al ruido
  — y lo hace en la latencia, no en el throughput
- Compresión `lz4` y `zstd`
- Combinar parámetros, y por qué se hace al final
- El lado del consumidor con `kafka-consumer-perf-test`, y la trampa del
  `rebalance.time.ms`
- Particionado por clave y *hot partitioning*

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Otro clúster Kafka detenido | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

Luego abre `guia/01-medir-y-comparado-con-que.md`, o `practica/PASOS.md` si
prefieres el recorrido en seco.

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Test de rendimiento de producción | `kafka-cli/perf-test.sh <TOPIC> N [opciones]` |
| Test de rendimiento de consumo | `kafka-cli/consumer-perf-test.sh <TOPIC> N [opciones]` |
| Kafbat UI | http://localhost:8090 |

---

## Tópicos del laboratorio

| Tópico | Particiones | RF | MIR | Propósito |
|--------|-------------|----|----|-----------|
| `novatech.tuning.bench` | 6 | 3 | 2 | Benchmarks de rendimiento |

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- Kafbat UI — interfaz web open-source — vía `ghcr.io/kafbat/kafka-ui`
- Bash scripts
- Docker & Docker Compose v2

---

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.
>
> **Valida tu avance** en cualquier momento: `bin/90-test-lab.sh`.

*Lab 07 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
