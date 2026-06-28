# Lab 04: Operando tópicos como un DBA

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 2 - Instalación, configuración y operación básica  
**Cubre los ítems**: 4, 5 y 6 del Capítulo 2  
**Duración estimada**: ~110 minutos

---

## Contexto narrativo

NovaTech tiene un nuevo requerimiento del CTO: **cada tipo de dato del negocio merece su propio tópico con configuración específica**. No todos los datos tienen el mismo perfil:

- **Telemetría GPS**: gran volumen, retención corta
- **Eventos de auditoría**: compliance, retención de 90 días
- **Estado actual de cada vehículo**: solo el último valor importa (compactación)
- **Alertas críticas**: máxima durabilidad

Tu misión: crear cada tópico con la configuración exacta, modificarlos cuando los requerimientos cambien, y demostrar que las configs efectivamente cambian el comportamiento.

---

## ¿Qué vas a aprender?

- Anatomía completa de un tópico (particiones, ISR, configs efectivas)
- Crear tópicos con `--config` (retención, compactación, replicación)
- Modificar tópicos en caliente sin downtime
- Aumentar particiones (y entender por qué no se pueden disminuir)
- Producción masiva y medición de throughput
- Plan de reasignación para cambiar RF (avanzado)

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Labs 01-03 detenidos | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

Luego abre `guia/01-anatomia-topico.md`.

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Reset | `bin/reset-lab.sh` |
| Listar tópicos | `kafka-cli/list-topics.sh [--internal]` |
| Crear tópico | `kafka-cli/create-topic.sh <NOMBRE> [opciones]` |
| Describir tópico | `kafka-cli/describe-topic.sh <NOMBRE>` |
| Modificar config | `kafka-cli/alter-topic-config.sh <NOMBRE> --add KEY=VALUE` |
| Modificar particiones | `kafka-cli/alter-topic-partitions.sh <NOMBRE> N` |
| Eliminar tópico | `kafka-cli/delete-topic.sh <NOMBRE>` |
| Producir N mensajes | `kafka-cli/produce-bulk.sh <NOMBRE> N [--key-pattern P]` |
| Test de throughput | `kafka-cli/perf-test.sh <NOMBRE> N [TAMAÑO]` |
| Kafbat UI | http://localhost:8090 |

---

## Tecnologías

- Apache Kafka 4.2 (KRaft) — `confluentinc/cp-kafka:8.2.0`
- Kafbat UI — `ghcr.io/kafbat/kafka-ui`
- Bash + Docker Compose v2

---

*Lab 04 - Curso de Administración de Apache Kafka con Confluent Platform*
