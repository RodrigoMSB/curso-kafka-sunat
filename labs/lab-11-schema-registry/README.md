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
chmod +x bin/*.sh kafka-cli/*.sh schema-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

⏰ La primera vez tarda 3-5 minutos (descarga de imágenes + arranque de Schema Registry).

Luego abre `guia/01-schema-registry.md`.

---

## URLs principales

| Servicio | URL | Para qué |
|---|---|---|
| Kafbat UI | http://localhost:8090 | Vista general (incluye Schema Registry) |
| Schema Registry | http://localhost:8081 | API REST para schemas |

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

---

## Tópicos del laboratorio

| Tópico | Particiones | RF | Propósito |
|--------|-------------|----|-----------|
| `novatech.lab10.pedidos` | 12 | 3 | Stream principal de pedidos (Avro) |
| `novatech.lab10.clientes` | 3 | 3 | Clientes en formato Avro |
| `_schemas` | 1 | 3 | Interno de Schema Registry |

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- **OpenJDK 17** — embebido en las imágenes Docker, no requiere instalación local
- Confluent Schema Registry 8.2.0
- Avro como formato de serialización
- Kafbat UI con integración a Schema Registry
- Bash + curl + Docker Compose v2

---

## Diferencias con Labs anteriores

| Aspecto | Lab 11 |
|---|---|
| Stack | CP 8.2.0 / Kafka 4.2 |
| Servicios nuevos | Schema Registry |
| RAM Docker | 6 GB |
| Total contenedores | 5 |

---

## Honestidad pedagógica

- **Schema Registry en producción real** se despliega como cluster de alta disponibilidad. Aquí 1 instancia para simplicidad.
- **Avro vs JSON Schema vs Protobuf**: Avro es el más maduro en el ecosistema Kafka, pero las alternativas también funcionan.

---

> **Nota:** los identificadores internos (nombres de tópicos/archivos) conservan el número del lab de origen; es intencional.

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.
>
> **Valida tu avance** en cualquier momento: `bin/90-test-lab.sh`.

*Lab 11 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
