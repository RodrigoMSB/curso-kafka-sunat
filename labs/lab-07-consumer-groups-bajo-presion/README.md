# Lab 07: Consumer groups bajo presión

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 3 - Administración avanzada  
**Cubre el ítem**: 4 del Capítulo 3  
**Duración estimada**: ~120 minutos

---

## Contexto narrativo

NovaTech tiene 3 áreas de procesamiento corriendo en paralelo:
- **Dashboard** (5 consumers): visualiza eventos en tiempo real
- **Alertas** (8 consumers): procesa eventos críticos
- **Reportes** (3 consumers): agrega datos para análisis

El equipo de operaciones llega a tu escritorio:

*"El lag del área de alertas crece sin parar los lunes a las 9 AM. Y cuando reiniciamos un consumer, el rebalanceo demora 30 segundos. Necesito que diagnostiques y optimices esto."*

Tu misión: experimentar con estrategias de asignación, diagnosticar lag bajo carga, observar rebalanceos en vivo, y manejar offsets manualmente.

---

## ¿Qué vas a aprender?

- Estrategias de asignación: Range, RoundRobin, Sticky, CooperativeSticky
- Cómo medir y diagnosticar lag con `kafka-consumer-groups`
- Rebalanceo: cuánto tarda, eager vs cooperative
- Reset de offsets por timestamp y por offset específico
- Cómo saltar mensajes "venenosos"
- Patrón Dead Letter Queue (DLQ)

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Labs 01-06 detenidos | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

Luego abre `guia/01-estrategias-de-asignacion.md`.

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Consumir con estrategia | `kafka-cli/consume-with-strategy.sh --group X --strategy Y` |
| Producir flood (generar lag) | `kafka-cli/produce-flood.sh N` |
| Monitor de lag | `kafka-cli/monitor-lag.sh GROUP [INTERVAL]` |
| Reset por timestamp | `kafka-cli/reset-to-timestamp.sh GROUP TIMESTAMP_ISO` |
| Reset a offset | `kafka-cli/reset-to-offset.sh GROUP PARTITION OFFSET` |
| Saltar mensaje venenoso | `kafka-cli/skip-poison-message.sh GROUP PARTITION` |
| Consumer con DLQ | `kafka-cli/consume-with-dlq.sh --group X --pattern Y` |
| Listar grupos | `kafka-cli/list-groups.sh` |
| Describir grupo | `kafka-cli/describe-group.sh GROUP` |
| Kafbat UI | http://localhost:8090 |

---

## Tópicos del laboratorio

| Tópico | Particiones | RF | Propósito |
|--------|-------------|----|-----------|
| `novatech.lab07.eventos` | 12 | 3 | Tópico principal con muchas particiones |
| `novatech.lab07.dlq` | 3 | 3 | Dead Letter Queue |

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- Kafbat UI — interfaz web open-source — vía `ghcr.io/kafbat/kafka-ui`
- Bash scripts
- Docker & Docker Compose v2

---

*Lab 07 - Curso de Administración de Apache Kafka con Confluent Platform*
