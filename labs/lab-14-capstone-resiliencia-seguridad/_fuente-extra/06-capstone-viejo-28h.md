# Parte 6: Capstone — evaluación final integradora

## Objetivo

Demostrar que dominas Kafka armando un **pipeline integrador end-to-end** que combina lo aprendido en los Labs 09, 10 y 11.

> **Decisión pedagógica**: este capstone **NO duplica infraestructura**. Reutilizas los stacks ya levantados en los Labs 09, 10 y 11 — porque la lección no es "armar todo otra vez", sino "tomar piezas existentes y hacerlas conversar". Esto es exactamente lo que harás en producción.

---

## Reglas

- **Tiempo sugerido**: 45–60 min.
- Trabajas con los Labs 09, 10 y 11 levantados (en distintos compose, en redes Docker separadas).
- Documentas en `plantillas/reporte-evaluacion-final.md` (copia y rellena).
- Si te trabas, mira `soluciones/respuestas-desafio.md` (pero solo después de intentarlo).

---

## El pipeline que vas a construir

```
┌─────────────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────────┐
│  PostgreSQL     │ →  │ Kafka topic  │ →  │ ksqlDB       │ →  │ Grafana     │
│  (pedidos)      │    │ (raw)        │    │ (enriquecido)│    │ (lag, etc.) │
│  Lab 09         │    │ Lab 09/10    │    │ Lab 10       │    │ Lab 11      │
└─────────────────┘    └──────────────┘    └──────────────┘    └─────────────┘
```

**Lo que tu pipeline debe hacer:**

1. Insertar un pedido en PostgreSQL (Lab 09).
2. Kafka Connect (JDBC Source) lo publica en un topic.
3. ksqlDB (Lab 10) lee ese topic, enriquece el pedido con un JOIN contra una tabla de clientes, y publica al topic enriquecido.
4. Verificas el lag del consumer en Grafana (Lab 11).

> **Nota**: los Labs 09 y 10 están en compose separados con redes distintas. Para que ksqlDB del Lab 10 lea un topic del Lab 09, lo más práctico es **simular el mismo flujo** dentro del Lab 10 (insertar el JSON ya enriquecido directamente al topic del Lab 10 con el script `produce-pedido.sh`). El espíritu del capstone se mantiene. Si tienes ambición, puedes conectar las redes Docker (`docker network connect`) y lo veremos como bonus.

---

## Pre-requisitos

Antes de empezar, valida que los stacks de Labs 09, 10 y 11 estén levantados:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'kafka-broker|ksqldb|prometheus|grafana|postgres|kafka-connect'
```

Deberías ver containers de los 3 labs corriendo. Si no, ve a cada lab y ejecuta `bin/start-lab.sh`.

---

## Desafío 1: Insertar un pedido en PostgreSQL y verificar que llega al topic (Lab 09)

**Objetivo**: validar que el pipeline Connect → Kafka funciona.

**Pasos**:

1. Ve a `labs/lab-09-kafka-connect/`.
2. Inserta un nuevo pedido:
   ```bash
   docker exec postgres psql -U novatech -d novatech_orders \
     -c "INSERT INTO pedidos (cliente_id, producto, cantidad, monto, estado) VALUES (5001, 'Capstone test', 2, 199.50, 'pendiente');"
   ```
3. Verifica que el JDBC Source connector lo publicó (consume desde el tópico
   y presiona Ctrl+C cuando veas tu pedido nuevo):
   ```bash
   kafka-cli/consume-pedidos.sh
   ```

**Llena en el reporte**:

| Campo | Valor |
|-------|-------|
| ¿El connector está RUNNING? | |
| ¿Cuál es el ID del último pedido recibido? | |
| ¿En qué partición cayó? | |

---

## Desafío 2: Crear un STREAM y un JOIN en ksqlDB (Lab 10)

**Objetivo**: enriquecer cada pedido con los datos del cliente.

**Pasos**:

1. Ve a `labs/lab-10-schema-registry-ksqldb/`.
2. Abre la CLI:
   ```bash
   docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
   ```
3. Crea un STREAM `pedidos_capstone` sobre el topic `novatech.lab10.pedidos`:
   ```sql
   CREATE STREAM pedidos_capstone (
     pedido_id INT, cliente_id INT, producto VARCHAR, monto DOUBLE
   ) WITH (KAFKA_TOPIC='novatech.lab10.pedidos', VALUE_FORMAT='AVRO');
   ```
4. (Si no tienes ya una tabla de clientes del Lab 10) Crea una TABLE de clientes:
   ```sql
   CREATE TABLE clientes_capstone (cliente_id INT PRIMARY KEY, nombre VARCHAR, vip BOOLEAN)
     WITH (KAFKA_TOPIC='novatech.lab10.clientes', VALUE_FORMAT='AVRO', KEY_FORMAT='AVRO');
   ```
5. Crea un STREAM derivado con JOIN:
   ```sql
   CREATE STREAM pedidos_enriquecidos AS
     SELECT p.pedido_id, p.producto, p.monto, c.nombre, c.vip
     FROM pedidos_capstone p
     INNER JOIN clientes_capstone c ON p.cliente_id = c.cliente_id;
   ```
6. Inserta un pedido y verifica:
   ```sql
   SET 'auto.offset.reset'='earliest';
   SELECT * FROM pedidos_enriquecidos EMIT CHANGES;
   ```

**Llena en el reporte**:

| Campo | Valor |
|-------|-------|
| ¿El STREAM derivado se creó sin errores? | |
| ¿Cuántos partitions tiene `pedidos_enriquecidos`? | |
| ¿Qué condición debe cumplirse para que el JOIN funcione? | |

> **Pista** sobre la última: co-particionamiento — los topics origen deben tener el mismo número de partitions y la misma key.

---

## Desafío 3: Verificar el pipeline en Grafana (Lab 11)

**Objetivo**: leer un dashboard de observabilidad y diagnosticar.

**Pasos**:

1. Ve a `labs/lab-11-prometheus-grafana/`.
2. Abre Grafana en `http://localhost:3000` (admin/admin).
3. Identifica el panel "Consumer lag por grupo" (o equivalente).

**Llena en el reporte**:

| Campo | Valor |
|-------|-------|
| ¿Qué consumer groups ves activos? | |
| ¿Cuál tiene mayor lag y por qué? | |
| ¿Qué métrica usarías para detectar un broker no disponible? | |

---

## Desafío 4: Aplicar lo de seguridad al pipeline (este lab)

**Pregunta de diseño** (no se ejecuta, se justifica por escrito):

Si llevaras este pipeline a producción y necesitaras seguridad, **¿qué cambios harías a cada lab?**

| Componente | Cambio que aplicarías |
|------------|------------------------|
| Lab 09 (Kafka Connect) | |
| Lab 10 (Schema Registry + ksqlDB) | |
| Lab 11 (Prometheus scraping JMX) | |
| Cluster en general | |

> **Ejemplos de respuestas válidas**: TLS en todos los listeners, SASL en Connect/ksqlDB para autenticarse al broker, ACLs por servicio (Connect tiene su user, ksqlDB el suyo), super.users acotado a 1 admin humano, certificados rotados por cert-manager o similar.

---

## Desafío 5 (opcional): conectar redes Docker

**Reto**: hacer que ksqlDB del Lab 10 lea directamente del topic del Lab 09 sin republicar.

```bash
docker network connect novatech-lab09-net ksqldb-server
```

Después, en ksqlDB, crea un STREAM apuntando al broker del Lab 09. Si te funciona, **describe en el reporte qué bootstrap servers usaste y cómo lo verificaste**.

---

## Entrega

1. Copia `plantillas/reporte-evaluacion-final.md` y completa cada celda.
2. Si tienes screenshots (panel de Grafana, salida de la JOIN), inclúyelos.
3. Compara después con `soluciones/reporte-resuelto.md`.

---

## Reflexión final del curso

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál fue el lab más difícil para ti, y por qué? | |
| ¿Qué concepto te costó más, y cómo terminaste de entenderlo? | |
| Si tuvieras que llevar Kafka a producción mañana, ¿qué priorizarías? | |
| ¿Qué te falta aprender que este curso no cubrió y vas a investigar? | |

---

## Has terminado el curso

Cubriste 28 horas de Kafka — desde conceptos básicos hasta operación productiva, integración con Schema Registry/ksqlDB/Connect, observabilidad y seguridad.

Lo que viene depende de ti: leer KIP propuestos, contribuir a un connector open-source, sacar la certificación CCDAK o CCAAK, o llevar Kafka a un proyecto real de tu empresa.

> *"En Kafka, los datos no se copian: se replican, se ordenan y se conservan. Y eso lo cambia todo."*
