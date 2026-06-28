# Lab 08: Monitoreo profesional con Confluent Control Center

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 3 - Administración avanzada (CIERRE DEL CAPÍTULO)  
**Cubre los ítems**: 5 y 6 del Capítulo 3  
**Duración estimada**: ~125 minutos

---

## ⚠️ Nota técnica importante

Este lab usa **Confluent Platform 7.9.0** (no 8.2.0 como los labs anteriores) para
poder usar Confluent Control Center Legacy. La versión de Kafka es 3.7 en lugar
de 4.2, pero todos los conceptos del curso aplican igual.

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 6 GB (igual que labs anteriores) |
| Disco libre | 10 GB |
| Puertos libres | 9092, 9093, 9094, 8090, 9021 |
| Labs 01-07 detenidos | OBLIGATORIO |

---

## Contexto narrativo

NovaTech ha crecido. Ya no basta con Kafbat UI: el equipo de operaciones necesita dashboards profesionales, alertas automáticas y visión histórica de métricas. El CTO te dice:

*"Quiero que el equipo NOC pueda ver el clúster en tiempo real, recibir alertas cuando un broker se atrase, y tener dashboards que pueda mostrar al directorio. Levanta Confluent Control Center y demuéstrame qué podemos monitorear."*

Tu misión: levantar el stack completo de monitoreo, generar carga real, ver las métricas fluir, y diseñar al menos una alerta personalizada.

---

## ¿Qué vas a aprender?

- Arquitectura de monitoreo con `ConfluentMetricsReporter` y tópico `_confluent-metrics`
- Diferencia entre `cp-kafka` (open) y `cp-server` (enterprise)
- Cómo Confluent Control Center Legacy visualiza un clúster
- Configurar triggers/alertas nativas en CC
- Comparar herramientas de monitoreo open-source (Kafbat) vs enterprise (CC)

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

⏰ La primera vez tarda 3-5 minutos (descarga de imágenes nuevas).

Luego abre `guia/01-arquitectura-monitoreo.md`.

---

## URLs principales

| Servicio | URL | Para qué |
|---|---|---|
| Control Center | http://localhost:9021 | LA ESTRELLA del lab |
| Kafbat UI | http://localhost:8090 | Comparativa con CC |

---

## Tópicos del laboratorio

| Tópico | Particiones | RF | Propósito |
|--------|-------------|----|-----------|
| `novatech.lab08.transactions` | 12 | 3 | Tópico de carga para métricas |
| `novatech.lab08.alerts` | 3 | 3 | Para experimentar con alertas |

---

## Tecnologías utilizadas

- Apache Kafka 3.7 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-server:7.9.0` (Confluent Platform 7.9)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- **Confluent Control Center 7.9.0** (Legacy)
- Kafbat UI — para comparativa
- Bash + Docker Compose v2

---

## Diferencias con Labs 01-07

| Aspecto | Labs 01-07 | Lab 08 |
|---|---|---|
| Imagen broker | `cp-kafka:8.2.0` (Kafka 4.2) | **`cp-server:7.9.0`** (Kafka 3.7) |
| RAM Docker | 6 GB | 6 GB (igual) |
| Contenedores | 5 | 6 |
| Control Center | No | **Sí (LA ESTRELLA)** |

---

## Honestidad pedagógica

Este lab usa una configuración de evaluación de Confluent Platform 7.9 con CC Legacy. La license se otorga automáticamente en período de prueba. Existe una versión más nueva (CC Next-Gen 2.x) basada en Prometheus + OTLP + Alertmanager, pero su setup tiene quirks no documentados que impiden un onboarding limpio en aula. Los conceptos de monitoreo (qué medir, alertas, troubleshooting) son idénticos en ambas versiones.

En producción típicamente se usaría: imágenes con tags fijos, Schema Registry y Connect desplegados, dashboards personalizados de Grafana junto a CC, y alertas integradas con Slack/PagerDuty.

---

*Lab 08 - Curso de Administración de Apache Kafka con Confluent Platform*
