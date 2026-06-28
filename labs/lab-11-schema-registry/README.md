# Lab 11: Schema Registry

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 4 - Avanzado, ecosistema, HA/DR y seguridad  
**Duración estimada**: ~60 minutos

---

## Contexto narrativo

Los equipos de analytics, fulfillment y notificaciones de NovaTech consumen cada uno el tópico `pedidos`, pero **no se pusieron de acuerdo en el formato**. Uno espera `cliente_id` (camelCase), otro `clienteId`, otro `client_id`. Cada cambio rompe a alguien. **NovaTech necesita un contrato de datos**.

El CTO te encarga:
*"Levanta Schema Registry para que los equipos firmen un contrato Avro y nadie pueda romperlo. Quiero que ningún productor pueda enviar un mensaje que no respete el schema."*

---

## ¿Qué vas a aprender?

- Por qué los schemas son críticos en Kafka
- Schema Registry: arquitectura, compatibility modes (BACKWARD, FORWARD, FULL)
- Avro: schemas vs JSON Schema, ventajas (binario, evolutivo)

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 6 GB |
| Disco libre | 10 GB |
| Puertos libres | 9092, 9093, 9094, 8090, 8081 |
| Otro clúster Kafka detenido | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh schema-cli/*.sh ksql-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

⏰ La primera vez tarda 3-5 minutos (descarga de imágenes + arranque de ksqlDB).

Luego abre `guia/01-schema-registry.md`.

---

## URLs principales

| Servicio | URL | Para qué |
|---|---|---|
| Kafbat UI | http://localhost:8090 | Vista general (incluye Schema Registry y ksqlDB) |
| Schema Registry | http://localhost:8081 | API REST para schemas |
| ksqlDB Server | http://localhost:8088 | API REST para queries |

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Listar subjects | `schema-cli/list-subjects.sh` |
| Registrar schema | `schema-cli/register-schema.sh <subject> <archivo.avsc>` |
| Verificar compatibilidad | `schema-cli/check-compatibility.sh <subject> <archivo.avsc>` |
| Producir pedido Avro | `kafka-cli/produce-pedido-avro.sh` |
| Producir cliente Avro | `kafka-cli/produce-cliente-avro.sh` |
| Flood de pedidos | `kafka-cli/produce-flood-pedidos.sh N` |
| Consumir Avro | `kafka-cli/consume-avro.sh <topic>` |
| Abrir ksqlDB CLI | `ksql-cli/ksql-shell.sh` |
| Mostrar streams/tables | `ksql-cli/show-streams.sh` |
| Ejecutar archivo .sql | `ksql-cli/execute-file.sh <archivo.sql>` |

---

## Tópicos del laboratorio

| Tópico | Particiones | RF | Propósito |
|--------|-------------|----|-----------|
| `novatech.lab10.pedidos` | 12 | 3 | Stream principal de pedidos (Avro) |
| `novatech.lab10.clientes` | 3 | 3 | Tabla de clientes para JOINs (Avro) |
| `_schemas` | 1 | 3 | Interno de Schema Registry |
| `_confluent-ksql-novatech_*` | varios | 3 | Internos de ksqlDB |

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- Confluent Schema Registry 8.2.0
- ksqlDB Server + CLI 8.2.0
- Avro como formato de serialización
- Kafbat UI con integración a Schema Registry y ksqlDB
- Bash + curl + Docker Compose v2

---

## Diferencias con Labs anteriores

| Aspecto | Lab 10 |
|---|---|
| Stack | CP 8.2.0 / Kafka 4.2 |
| Servicios nuevos | Schema Registry, ksqlDB Server, ksqlDB CLI |
| RAM Docker | 6 GB |
| Total contenedores | 7 |

---

## Honestidad pedagógica

- **ksqlDB no reemplaza Kafka Streams (Java)** en casos complejos. Es una herramienta para analistas y prototipado rápido. Las queries persistent SON aplicaciones Kafka Streams compiladas dinámicamente.
- **Schema Registry en producción real** se despliega como cluster de alta disponibilidad. Aquí 1 instancia para simplicidad.
- **Avro vs JSON Schema vs Protobuf**: Avro es el más maduro en el ecosistema Kafka, pero las alternativas también funcionan.

---

*Lab 11 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
