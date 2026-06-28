# Parte 2: Avro en acción

## Objetivo

Producir y consumir mensajes en formato Avro. Ver cómo Avro se integra automáticamente con Schema Registry. Comparar Avro con JSON.

## Contexto

**Avro** es un formato de serialización binario que:
- Pesa MENOS que JSON (campos no se repiten en cada mensaje)
- Lleva un **schema ID** (4 bytes) en cada mensaje
- Permite evolución de schema con compatibility checks
- Es el estándar de facto en el ecosistema Confluent

---

## Actividad 1: Producir un pedido Avro

```bash
kafka-cli/produce-pedido-avro.sh 1 1001 "Caja premium" 10 25000.00 pendiente
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El mensaje se publicó sin error? | |

Si falló porque `kafka-avro-console-producer` no encuentra el schema, primero registra el schema (Parte 1).

---

## Actividad 2: Consumir el pedido y ver el JSON

```bash
kafka-cli/consume-avro.sh novatech.lab10.pedidos
```

(Espera ~5s, luego Ctrl+C.)

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Apareció el mensaje en formato JSON? | |
| ¿Quién deserializó el binario Avro a JSON? | |

> **Pista**: `kafka-avro-console-consumer` consulta SR por el schema ID, baja el schema, y deserializa.

---

## Actividad 3: Producir 5 pedidos más

```bash
kafka-cli/produce-pedido-avro.sh 2 1002 "Pallet reforzado" 5 89000.00 en_proceso
kafka-cli/produce-pedido-avro.sh 3 1003 "Etiquetas RFID" 100 45000.00 pendiente
kafka-cli/produce-pedido-avro.sh 4 1001 "Cinta industrial" 50 7500.00 enviado
kafka-cli/produce-pedido-avro.sh 5 1004 "Stretch film" 30 18000.00 pendiente
kafka-cli/produce-pedido-avro.sh 6 1002 "Cartón premium" 200 65000.00 entregado
```

---

## Actividad 4: Verificar en Kafbat UI

Abre **http://localhost:8090** > **Topics** > `novatech.lab10.pedidos` > **Messages**.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes ves? | |
| ¿Kafbat los muestra en JSON deserializado o binario? | |
| ¿Aparece el schema en la pestaña "Schema"? | |

> **Pista**: Kafbat tiene integración nativa con SR (configurada en `KAFKA_CLUSTERS_0_SCHEMAREGISTRY`). Por eso muestra los mensajes Avro como JSON legible.

---

## Actividad 5: Generar carga masiva

```bash
kafka-cli/produce-flood-pedidos.sh 50
```

Verifica el throughput en Kafbat UI (gráfico de mensajes/seg en el tópico).

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Llegaron los 50 pedidos? | |
| ¿Throughput en Kafbat UI? | |

---

## Actividad 6: Producir clientes (para JOIN en Parte 4)

```bash
kafka-cli/produce-cliente-avro.sh 1001 "Acme S.A." VIP Santiago
kafka-cli/produce-cliente-avro.sh 1002 "Beta Logistics" ESTANDAR Valparaiso
kafka-cli/produce-cliente-avro.sh 1003 "Carga Sur" ESTANDAR Concepcion
kafka-cli/produce-cliente-avro.sh 1004 "Delta Express" VIP Santiago
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 4 clientes se publicaron? | |

```bash
kafka-cli/consume-avro.sh novatech.lab10.clientes
```

(Ctrl+C tras ver los 4.)

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué tamaño aproximado tiene un mensaje Avro vs JSON con los mismos datos? | |
| ¿Por qué Avro es mejor que JSON para Kafka a gran escala? | |
| ¿Qué pasaría si publicas un mensaje con `monto` como string en vez de double? | |

> **Pista**: Avro es 2-10x más compacto que JSON. Schema Registry rechaza mensajes que no cumplan el schema en el momento de producir, así que un `monto` como string ni siquiera llega al tópico.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Avro binario | Producido y consumido |
| Integración con SR | Producer y consumer consultan SR por el schema |
| Validación automática | El producer no permite mensajes mal formateados |
| Kafbat UI + SR | Visualización JSON automática |

---

## Siguiente paso

Continúa con [Parte 3: ksqlDB fundamentos](03-ksqldb-fundamentos.md).
