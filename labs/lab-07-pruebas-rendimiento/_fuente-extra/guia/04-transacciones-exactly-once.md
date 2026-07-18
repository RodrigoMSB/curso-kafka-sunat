# Parte 4: Transacciones exactly-once

## Objetivo

Producir a múltiples tópicos atómicamente. Demostrar que un consumer con `isolation.level=read_committed` solo ve mensajes de transacciones commiteadas.

## Contexto

Para exactly-once a través de múltiples particiones (o múltiples tópicos), Kafka ofrece transacciones:
1. El productor declara un `transactional.id` único
2. Inicia transacción → produce → commit (o abort)
3. El consumer con `read_committed` solo ve commits

> **Limitación pedagógica**: el control fino de transacciones requiere código de aplicación con la API del cliente Kafka. En este lab usamos `kafka-verifiable-producer` y `kafka-transactions` para ilustrar el concepto.

---

## Actividad 1: Producción transaccional COMMIT

```bash
kafka-cli/produce-transactional.sh 5
```

Esto produce 5 mensajes en `novatech.payments.attempts` Y 5 en `novatech.payments.confirmed` dentro de transacciones.

---

## Actividad 2: Consumir con read_committed

```bash
kafka-cli/consume-isolated.sh novatech.payments.confirmed read_committed --max 10
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes viste? | |
| ¿Todos? | |

---

## Actividad 3: Producción con ABORT

```bash
kafka-cli/produce-transactional.sh 5 --abort
```

> **Nota pedagógica**: la implementación del abort en este lab usa `kafka-verifiable-producer` con limitaciones. En producción real, el abort transaccional se controla desde el código de la aplicación con `producer.abortTransaction()`.

---

## Actividad 4: Consumir con AMBOS isolation levels

Con `read_uncommitted`:
```bash
kafka-cli/consume-isolated.sh novatech.payments.confirmed read_uncommitted --max 20
```

Con `read_committed`:
```bash
kafka-cli/consume-isolated.sh novatech.payments.confirmed read_committed --max 20
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes con read_uncommitted? | |
| ¿Cuántos mensajes con read_committed? | |
| ¿La diferencia te indica los mensajes abortados? | |

---

## Actividad 5: Inspeccionar transacciones

```bash
kafka-cli/list-transactions.sh
```

Si hay transacciones activas, descríbelas:

```bash
kafka-cli/describe-transaction.sh <ID_DE_TU_TRANSACCION>
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas transacciones aparecen? | |
| ¿En qué estado están? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Transacciones cross-topic | Produciste a 2 tópicos atómicamente |
| read_committed | Solo ves transacciones commiteadas |
| read_uncommitted | Ves todo, incluyendo abortadas |
| Exactly-once cross-partition | Solo se logra con transacciones |

---

## Siguiente paso

Continúa con [Desafío 5: Particionado y throughput](05-desafio-particionado-y-throughput.md) (opcional).
