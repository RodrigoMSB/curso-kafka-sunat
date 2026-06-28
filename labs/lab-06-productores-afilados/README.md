# Lab 06: Productores afilados al milímetro

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 3 - Administración avanzada  
**Cubre el ítem**: 3 del Capítulo 3  
**Duración estimada**: ~120 minutos

---

## Contexto narrativo

El equipo de pagos de NovaTech (cobros por kilometraje, peajes y mantenimientos) escala a tu mesa con un problema crítico:

*"A veces los pagos se duplican. A veces se pierden. Necesito que las escrituras a Kafka sean exactly-once. Y mientras estás en eso, también necesito que el throughput suba."*

Tu misión: configurar productores idempotentes y transaccionales, demostrar empíricamente la diferencia con un productor naive, y tunear los parámetros de batching para subir el throughput.

---

## ¿Qué vas a aprender?

- Cómo `batch.size` y `linger.ms` afectan el throughput
- Diferencia entre `acks=0`, `acks=1` y `acks=all` (medida en vivo)
- Por qué un productor "naive" puede generar duplicados
- Cómo `enable.idempotence=true` los elimina
- Transacciones exactly-once a través de múltiples tópicos
- `isolation.level` desde el lado del consumer
- Particionadores: sticky, round-robin, custom

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Labs 01-05 detenidos | Sí |

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
| Test de throughput | `kafka-cli/perf-test.sh <TOPIC> N [opciones]` |
| Producción naive | `kafka-cli/produce-naive.sh <TOPIC> N` |
| Producción idempotente | `kafka-cli/produce-idempotent.sh <TOPIC> N` |
| Producción transaccional | `kafka-cli/produce-transactional.sh N [--abort]` |
| Consumir aislado | `kafka-cli/consume-isolated.sh <TOPIC> <ISOLATION>` |
| Listar transacciones | `kafka-cli/list-transactions.sh` |
| Kafbat UI | http://localhost:8090 |

---

## Tópicos del laboratorio

| Tópico | Particiones | RF | MIR | Propósito |
|--------|-------------|----|----|-----------|
| `novatech.payments.attempts` | 3 | 3 | 2 | Experimentos de duplicados |
| `novatech.payments.confirmed` | 3 | 3 | 2 | Experimentos transaccionales |
| `novatech.tuning.bench` | 6 | 3 | 2 | Benchmarks de tuning |

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- Kafbat UI — interfaz web open-source — vía `ghcr.io/kafbat/kafka-ui`
- Bash scripts
- Docker & Docker Compose v2

---

*Lab 06 - Curso de Administración de Apache Kafka con Confluent Platform*
