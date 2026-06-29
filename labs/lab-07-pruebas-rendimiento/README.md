# Lab 07: Pruebas de rendimiento

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento  
**Duración estimada**: ~60 minutos

---

## Contexto narrativo

El equipo de infraestructura de NovaTech necesita dimensionar el clúster antes de la temporada alta:

*"Necesito saber cuánto throughput aguanta el clúster produciendo y consumiendo, cuál es la latencia, y qué parámetros mover para exprimirlo. Mídelo en serio, con números."*

Tu misión: medir empíricamente el rendimiento de producción y consumo con las herramientas de perf-test, y tunear los parámetros del cliente (batch, linger, acks, compresión, fetch) para encontrar el punto óptimo.

---

## ¿Qué vas a aprender?

- Cómo `batch.size` y `linger.ms` afectan el throughput
- Diferencia entre `acks=0`, `acks=1` y `acks=all` (medida en vivo)
- Medir throughput y latencia de producción con `kafka-producer-perf-test`
- Medir throughput de consumo con `kafka-consumer-perf-test`
- Cómo el `fetch.size` y la compresión afectan el rendimiento
- Particionadores y su impacto en el throughput

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

Luego abre `guia/01-tuning-batch-y-linger.md`.

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

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- Kafbat UI — interfaz web open-source — vía `ghcr.io/kafbat/kafka-ui`
- Bash scripts
- Docker & Docker Compose v2

---

*Lab 07 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
