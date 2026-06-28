# Lab 11: Monitoreo con Prometheus + Grafana + tour Confluent Cloud

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 4 - Integración con sistemas externos  
**Cubre los ítems**: 7 y 8 del Capítulo 4  
**Duración estimada**: ~120 minutos

---

## ⚠️ Nota sobre Confluent Cloud

A diferencia de los labs anteriores, este lab tiene **2 partes con
metodologías distintas**:

1. **Prometheus + Grafana**: ejercicio práctico hands-on (cada alumno ejecuta).
2. **Confluent Cloud**: tour visual guiado por el instructor.

**¿Por qué tour y no práctico para Confluent Cloud?**

Confluent Cloud requiere agregar tarjeta de crédito personal (incluso para
el free tier de $400 USD). En contexto corporativo pedir tarjeta personal
genera fricciones legítimas. El instructor mantiene su propia cuenta para
mostrar el flujo completo en clase con capturas reales. Quienes quieran
replicar lo verán documentado en `guia/04` para hacerlo en casa.

---

## Contexto narrativo

Tras los logros del Cap 3 y 4 (Connect, Schema Registry, ksqlDB), el equipo
de operaciones de NovaTech tiene un dolor: **el monitoreo "casero" con
Kafbat UI no escala**. Quieren dashboards profesionales con histórico,
alertas automáticas, y métricas técnicas profundas.

El CTO te dice:
*"Ya tenemos Confluent Control Center (Lab 08) pero es comercial. Necesito
que evalúes la alternativa open-source: Prometheus + Grafana. Quiero ver
dashboards de la comunidad importados, métricas técnicas reales fluyendo,
y comparativa de costos vs Confluent Cloud."*

Tu misión: levantar Prometheus + Grafana, importar un dashboard popular,
generar carga real, y comparar las 3 opciones (Kafbat / Prometheus-Grafana / CC).

---

## ¿Qué vas a aprender?

- JMX Exporter: cómo exponer métricas JMX como endpoint HTTP de Prometheus
- Prometheus: scraping, PromQL básico
- Grafana: dashboards, paneles, importar dashboards de la comunidad
- Métricas críticas de Kafka: Bytes In/Out, Request Rate, ISR, URP
- Trade-offs: open-source (ops manual) vs Confluent Cloud (managed pero $$$)

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 6 GB |
| Disco libre | 10 GB |
| Puertos libres | 9092, 9093, 9094, 7071, 7072, 7073, 8090, 9090, 3000 |
| Labs 01-10 detenidos | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

⏰ La primera vez tarda 3-5 minutos.

Luego abre `guia/01-arquitectura-monitoreo.md`.

---

## URLs principales

| Servicio | URL | Para qué |
|---|---|---|
| Kafbat UI | http://localhost:8090 | Vista básica para comparar |
| Prometheus | http://localhost:9090 | Métricas crudas + PromQL |
| Grafana | http://localhost:3000 | LA ESTRELLA (admin/admin o anónimo) |

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Generar carga | `kafka-cli/produce-flood.sh DURATION RATE` |
| Tumbar broker | `kafka-cli/trigger-broker-down.sh <1|2|3>` |

---

## Tópicos del laboratorio

| Tópico | Particiones | RF | Propósito |
|--------|-------------|----|-----------|
| `novatech.lab11.eventos` | 12 | 3 | Generar carga monitoreable |

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker
- Prometheus v3.0.1 (open-source)
- Grafana 11.4.0 (open-source)
- JMX Exporter 1.0.1 (Java agent)
- Kafbat UI — para comparativa
- Bash + Docker Compose v2

---

## Diferencias con Labs anteriores

| Aspecto | Lab 11 |
|---|---|
| Stack | CP 8.2.0 / Kafka 4.2 |
| Servicios nuevos | Prometheus, Grafana, JMX Exporter (sidecar) |
| RAM Docker | 6 GB |
| Total contenedores | 6 |
| Imagen broker | `cp-kafka:8.2.0` (NO `cp-server`) |

---

## Honestidad pedagógica

- **Confluent Cloud como tour**: ver nota arriba.
- **Dashboard de la comunidad** (ID 11962) puede tener paneles "No data" porque
  las queries usan métricas que JMX Exporter no genera con esos nombres exactos.
  Esto es **enseñable**: dashboards comunitarios son punto de partida, no copy-paste.
- **JMX Exporter 1.0.1**: versión estable. JMX Exporter 1.x cambió formato vs 0.x.

---

*Lab 11 - Curso de Administración de Apache Kafka con Confluent Platform*
