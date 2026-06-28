# Lab 02: Pub/Sub y Consumer Groups en acción

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 1 - Fundamentos de Apache Kafka  
**Posición**: Post ítem 5  
**Duración estimada**: ~100 minutos

---

## Contexto narrativo

NovaTech Logistics tiene su clúster GPS funcionando (Lab 01). Ahora **el negocio creció** y tres áreas distintas necesitan consumir los datos de la flota:

- 📊 **Dashboard de Operaciones** — necesita ver TODO en tiempo real
- 🚨 **Sistema de Alertas** — necesita procesar cada evento sin perderlo, escalando horizontalmente
- 📈 **Módulo de Reportes Históricos** — necesita re-procesar datos antiguos para analítica

Tu jefe pregunta: *"¿Cómo hacemos que las 3 áreas vean los mismos datos sin pisarse? ¿Y cómo escalamos cuando alertas reciba 5x más volumen?"*

**Tu misión**: demostrar el modelo pub/sub de Kafka resolviendo este problema con experimentos en vivo.

---

## ¿Qué vas a hacer?

1. **Producir y consumir mensajes manualmente** para entender el log inmutable
2. **Lanzar múltiples consumidores independientes** (modelo broadcast)
3. **Lanzar consumidores en consumer groups** y ver cómo se reparten las particiones
4. **Resetear offsets** para "rebobinar el tiempo" y reprocesar mensajes
5. **Experimentar con claves** para entender el particionado consistente

---

## Prerrequisitos técnicos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM asignada a Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Lab 01 detenido (los puertos chocan) | Sí |

---

## Inicio rápido

```bash
# 1. Asegurar que el Lab 01 esté detenido
# (desde la carpeta del Lab 01: bin/stop-lab.sh)

# 2. Dar permisos de ejecución
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh

# 3. Iniciar el laboratorio
bin/start-lab.sh

# 4. Abrir la primera guía
# guia/01-log-inmutable.md
```

---

## Estructura del laboratorio

```
lab-02-pubsub-en-accion/
├── README.md                  # Este archivo
├── infra/
│   ├── docker-compose.yml     # Mismo clúster del Lab 01
│   ├── .env
│   └── scripts/
│       └── init-events-topic.sh
├── bin/
│   ├── common.sh
│   ├── start-lab.sh           # Levanta clúster + crea tópico
│   ├── stop-lab.sh
│   └── reset-lab.sh
├── kafka-cli/
│   ├── produce-event.sh       # Produce 1 mensaje
│   ├── consume-event.sh       # Consume sin grupo (broadcast)
│   ├── consume-as-group.sh    # Consume en grupo (escalable)
│   ├── list-groups.sh         # Lista todos los grupos
│   ├── describe-group.sh      # Detalle de un grupo (offsets, lag)
│   ├── reset-group.sh         # Resetea offsets a --to-earliest
│   └── show-partition-for-key.sh  # Predice partición destino
├── guia/
│   ├── 01-log-inmutable.md
│   ├── 02-pubsub-multiples-consumidores.md
│   ├── 03-consumer-groups.md
│   ├── 04-offsets-y-replay.md
│   └── 05-desafio-keys-y-particionado.md
├── plantillas/
│   └── reporte-entregable.md
├── soluciones/
│   ├── reporte-resuelto.md
│   └── respuestas-desafio.md
└── docs/
    └── troubleshooting.md
```

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar laboratorio | `bin/start-lab.sh` |
| Detener laboratorio | `bin/stop-lab.sh` |
| Reiniciar laboratorio | `bin/reset-lab.sh` |
| Producir 1 mensaje | `kafka-cli/produce-event.sh "<MENSAJE>"` |
| Producir con clave | `kafka-cli/produce-event.sh --key NVT-1001 "<MENSAJE>"` |
| Consumir sin grupo | `kafka-cli/consume-event.sh [--from-beginning]` |
| Consumir en grupo | `kafka-cli/consume-as-group.sh --group <NOMBRE>` |
| Listar grupos | `kafka-cli/list-groups.sh` |
| Describir grupo | `kafka-cli/describe-group.sh <NOMBRE>` |
| Resetear grupo | `kafka-cli/reset-group.sh <NOMBRE>` |
| Kafbat UI | http://localhost:8090 |

---

## Entregables

1. **Reporte completado**: `plantillas/reporte-entregable.md` con todas las secciones llenas
2. **(Opcional)** Sección del desafío con las observaciones del particionado por clave

---

## Problemas frecuentes

Consulta la [guía de troubleshooting](docs/troubleshooting.md) si encuentras problemas.

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0`
- Kafbat UI — interfaz web open-source — vía `ghcr.io/kafbat/kafka-ui`
- Bash scripts
- Docker & Docker Compose v2

---

*Lab 02 - Curso de Administración de Apache Kafka con Confluent Platform*
