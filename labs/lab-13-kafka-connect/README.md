# Lab 09: Kafka Connect con PostgreSQL

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 4 - Integración con sistemas externos  
**Cubre los ítems**: 1, 2 y 3 del Capítulo 4  
**Duración estimada**: ~120 minutos

---

## Contexto narrativo

NovaTech Logistics tiene un legacy crítico: una base de datos PostgreSQL llamada `novatech_orders` donde el sistema antiguo registra todos los pedidos. Hay miles de pedidos al día y los equipos de analytics, fulfillment, y notificaciones necesitan acceso en tiempo real, pero **NO pueden consultar directamente la DB** (saturación, acoplamiento).

El CTO te dice:
*"Necesito que conectes la tabla `pedidos` con Kafka. Cualquier pedido nuevo debe aparecer automáticamente en un tópico. Y cuando el equipo de fulfillment marque un pedido como 'procesado' publicando en otro tópico, esos cambios deben volver automáticamente a una tabla `pedidos_procesados`. Sin escribir código de aplicación: usa Kafka Connect."*

Tu misión: levantar Kafka Connect en modo distributed, configurar un JDBC Source para capturar pedidos, configurar un JDBC Sink para escribir resultados de vuelta a PostgreSQL, y demostrar el flujo end-to-end.

---

## ¿Qué vas a aprender?

- Arquitectura de Kafka Connect: workers, connectors, tasks, offset storage
- Diferencia entre **standalone** y **distributed**
- Cómo configurar un conector usando JSON via REST API
- Source connector: PostgreSQL → Kafka
- Sink connector: Kafka → PostgreSQL
- Por qué Connect es mejor que escribir código de integración custom

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 6 GB |
| Disco libre | 10 GB |
| Puertos libres | 9092, 9093, 9094, 8090, 5432, 8083 |
| Labs 01-08 detenidos | Sí |
| Acceso a internet | Sí (descarga plugin JDBC al primer arranque) |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh connect-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

⏰ La primera vez tarda 3-5 minutos (incluye descarga de imágenes + instalación del plugin JDBC).

Luego abre `guia/01-arquitectura-connect.md`.

---

## URLs principales

| Servicio | URL | Para qué |
|---|---|---|
| Kafbat UI | http://localhost:8090 | Vista general del clúster |
| Kafka Connect REST | http://localhost:8083 | Crear/listar/eliminar connectors |
| PostgreSQL | localhost:5432 | DB origen y destino (user `novatech`) |

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Reset completo | `bin/reset-lab.sh` |
| Crear Source connector | `connect-cli/create-source.sh` |
| Crear Sink connector | `connect-cli/create-sink.sh` |
| Listar connectors | `connect-cli/list-connectors.sh` |
| Estado de un connector | `connect-cli/status-connector.sh <NOMBRE>` |
| Eliminar connector | `connect-cli/delete-connector.sh <NOMBRE>` |
| Insertar pedido en DB | `kafka-cli/insertar-pedido.sh` |
| Consumir pedidos de Kafka | `kafka-cli/consume-pedidos.sh` |
| Publicar "procesado" | `kafka-cli/publicar-procesado.sh <ID>` |
| Verificar tabla destino | `kafka-cli/verificar-tabla-procesados.sh` |

---

## Tópicos del laboratorio

| Tópico | Origen | Propósito |
|--------|--------|-----------|
| `novatech.lab09.pedidos` | Source connector | Pedidos capturados de PostgreSQL |
| `novatech.lab09.pedidos.procesados` | Cliente publica | Sink connector lo escribe a `pedidos_procesados` |
| `_connect-configs`, `_connect-offsets`, `_connect-status` | Internos de Connect | Persistencia del estado del cluster Connect |

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- Kafka Connect — vía `confluentinc/cp-kafka-connect:8.2.0`
- PostgreSQL 16 — vía `postgres:16-alpine`
- Plugin JDBC — `confluentinc/kafka-connect-jdbc:10.8.0` (Confluent Hub)
- Driver PostgreSQL JDBC — `postgresql-42.7.4.jar` (Maven Central)
- Kafbat UI — para inspección visual del clúster y de Connect
- Bash + curl + Docker Compose v2

---

## Diferencias con Labs 01-08

| Aspecto | Lab 09 |
|---|---|
| Stack | CP 8.2.0 (vuelve después del Lab 08 con 7.9.0) |
| Servicios nuevos | PostgreSQL, Kafka Connect |
| RAM Docker | 6 GB (igual que labs 01-07) |
| Plugin JDBC | Se instala al arrancar (~90s extra primera vez) |

---

## Honestidad pedagógica

- Este lab usa **JDBC connector** porque es el más educativo. En producción real para CDC se usaría **Debezium** (lee el WAL de PostgreSQL, captura INSERT/UPDATE/DELETE en milisegundos). Lo mencionamos pero no lo implementamos.
- El plugin JDBC se instala al arrancar el contenedor. En producción se construye una imagen Docker custom con el plugin pre-instalado.
- Modo `incrementing` solo detecta INSERT, no UPDATE/DELETE. Para CDC completo, usar Debezium.

---

*Lab 09 - Curso de Administración de Apache Kafka con Confluent Platform*
