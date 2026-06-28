# Lab 05: Resiliencia y políticas de retención

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 3 - Administración avanzada de tópicos, productores, consumidores y flujo de datos  
**Cubre los ítems**: 1 y 2 del Capítulo 3  
**Duración estimada**: ~120 minutos

---

## Contexto narrativo

Es viernes a las 6 PM. La flota de NovaTech tiene miles de vehículos transmitiendo. Tu jefe te dice:

*"El datacenter B se cae mañana por mantenimiento. Demuéstrame que el clúster sobrevive a perder 1 broker, y luego un segundo. Y que las políticas de retención se respetan al pie de la letra. Quiero ver evidencia."*

Tu misión: validar la tolerancia a fallos del clúster bajo carga real, y experimentar con retención y compactación.

---

## ¿Qué vas a aprender?

- Cómo el ISR cambia dinámicamente cuando un broker cae
- Diferencia entre RF y `min.insync.replicas`
- Por qué Kafka bloquea escrituras cuando ISR < MIR
- Cómo se hace catch-up automático al revivir un broker
- Cómo `retention.ms` y `segment.ms` interactúan
- Compactación de logs y tombstones para eliminación lógica

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Labs 01-04 detenidos | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

Luego abre `guia/01-isr-bajo-microscopio.md`.

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Reset | `bin/reset-lab.sh` |
| Tumbar broker | `bin/kill-broker.sh <1\|2\|3>` |
| Revivir broker | `bin/revive-broker.sh <1\|2\|3>` |
| Producir continuo | `kafka-cli/produce-continuous.sh <TOPIC> [opciones]` |
| Producir bulk | `kafka-cli/produce-bulk.sh <TOPIC> N` |
| Producir tombstone | `kafka-cli/produce-tombstone.sh <TOPIC> <KEY>` |
| Monitor ISR | `kafka-cli/watch-isr.sh <TOPIC> [INTERVAL]` |
| Describir tópico | `kafka-cli/describe-topic.sh <TOPIC>` |
| Modificar config | `kafka-cli/alter-topic-config.sh <TOPIC> --add KEY=VALUE` |
| Listar tópicos | `kafka-cli/list-topics.sh` |
| Kafbat UI | http://localhost:8090 |

---

## Tópicos del laboratorio

| Tópico | RF | MIR | Otras configs |
|--------|----|----|---------------|
| `novatech.lab05.resiliente` | 3 | 2 | (default) |
| `novatech.lab05.estricto` | 3 | 3 | (default) |
| `novatech.lab05.efimero` | 3 | 2 | retention.ms=60s, segment.ms=10s |
| `novatech.lab05.estado` | 3 | 2 | compact, dirty.ratio=0.01 |

---

## Tecnologías

- Apache Kafka 4.2 (KRaft) — `confluentinc/cp-kafka:8.2.0`
- Kafbat UI — `ghcr.io/kafbat/kafka-ui`
- Bash + Docker Compose v2

---

*Lab 05 - Curso de Administración de Apache Kafka con Confluent Platform*
