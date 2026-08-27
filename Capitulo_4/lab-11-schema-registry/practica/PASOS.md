# Lab 11 · PASOS

> El recorrido en seco. Aquí están los comandos en orden y los huecos que tú
> rellenas mientras corren. **La explicación de por qué hace cada cosa está en
> la guía** — `guia/01-contrato-y-quien-autorizo-ese-campo.md`. Este archivo es
> para tener a mano en la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba y
Schema Registry respondiendo en `http://localhost:8081`.

**Cuánto toma:** la corrida completa son **7 segundos medidos** de ejecución.
Aquí no hay nada que esperar. Todo el tiempo que le dediques es tiempo de
pensar.

---

## Paso 1 · Escribir el contrato

**Primero mira el contrato antes de firmarlo.**

```bash
cat infra/schemas/pedido.avsc
```

| Hueco | Tu respuesta |
|---|---|
| ¿Cuántos campos tiene? | |
| ¿Cuántos de ellos traen la palabra `default`? | |

🔴 **La segunda respuesta es la que decide todo el laboratorio.** Si dudas,
vuelve al Paso 1 de la guía antes de seguir.

Ahora regístralo:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido.avsc
```

Anota de la salida:

| Campo | Lo que salió |
|---|---|
| `version` | |
| `id` | |
| `schemaType` | |

**La pregunta del paso:** `version` e `id` salieron los dos en 1. ¿Son el mismo
número por casualidad o por definición? ¿Cuál de los dos viaja pegado a cada
mensaje?

---

## Paso 2 · El cambio que parece inocente

**Antes de ejecutar, predice.** Mira la única diferencia:

```bash
diff infra/schemas/pedido.avsc infra/schemas/pedido-v3-incompatible.avsc
```

| Hueco | Tu respuesta |
|---|---|
| ¿Qué campo se agrega? | |
| ¿Se borró o se renombró algo? | |
| **Antes de correr nada: ¿va a entrar? Escribe sí o no aquí** | |

Ahora pregúntale al Registry sin escribir nada:

```bash
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

| Hueco | Lo que salió |
|---|---|
| `is_compatible` | |
| ¿Acertaste tu predicción? | |

E intenta registrarlo:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

Del mensaje de error, saca estos cuatro datos —están todos ahí adentro:

| Dato | Lo que salió |
|---|---|
| `error_code` | |
| `errorType` | |
| Qué campo nombra como culpable | |
| Contra qué versión comparó (`oldSchemaVersion`) | |
| Con qué regla juzgó (`compatibility`) | |

**La pregunta del paso:** el error dice dos condiciones sobre el campo culpable,
no una. ¿Cuáles son? Si solo se cumpliera una de las dos, ¿el cambio entraría?

---

## Paso 3 · Y no hay puerta trasera

Cuenta los mensajes que hay ahora:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1 \
  | awk -F: '{s+=$3} END {print s" mensajes"}'
```

| Medición | Cantidad |
|---|---|
| Mensajes antes de intentar nada | |

Ahora intenta escribir con el contrato que el Registry acaba de rechazar:

```bash
echo '{"id":99,"cliente_id":1001,"producto":"Caja premium","cantidad":1,"monto":25000.00,"estado":"pendiente","tarjeta_credito":"4111-1111-1111-1111"}' \
| MSYS_NO_PATHCONV=1 docker exec -i \
    -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
    schema-registry kafka-avro-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos \
    --reader-property schema.registry.url=http://schema-registry:8081 \
    --reader-property value.schema="$(tr -d '\n ' < infra/schemas/pedido-v3-incompatible.avsc)" \
  2>&1 | grep -oE "^org[^:]*Exception"
```

| Hueco | Lo que salió |
|---|---|
| ¿Qué excepción salió? | |
| La palabra clave de su nombre, ¿es *Serialization*, *Authorization* o *Broker*? | |
| ¿Qué te dice esa palabra sobre **dónde** murió el mensaje? | |

Vuelve a contar:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1 \
  | awk -F: '{s+=$3} END {print s" mensajes"}'
```

| Medición | Cantidad |
|---|---|
| Mensajes después del intento rechazado | |

**Ahora la otra mitad.** El mismo comando, cambiando **solo el archivo del
contrato**:

```bash
echo '{"id":1,"cliente_id":1001,"producto":"Caja premium","cantidad":10,"monto":25000.00,"estado":"pendiente"}' \
| MSYS_NO_PATHCONV=1 docker exec -i \
    -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
    schema-registry kafka-avro-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos \
    --reader-property schema.registry.url=http://schema-registry:8081 \
    --reader-property value.schema="$(tr -d '\n ' < infra/schemas/pedido.avsc)" \
  2>&1 | grep -oE "^org[^:]*Exception"
```

Y cuenta por tercera vez:

| Medición | Cantidad |
|---|---|
| ¿Qué imprimió el comando esta vez? | |
| Mensajes después del intento aceptado | |

**La pregunta del paso:** el broker no sabe nada de contratos y aun así el
mensaje no llegó. ¿Quién lo frenó, y en qué máquina corría ese código?

---

## Paso 4 · El cambio que sí pasa

```bash
diff infra/schemas/pedido.avsc infra/schemas/pedido-v2-compatible.avsc
```

| Hueco | Tu respuesta |
|---|---|
| ¿Qué campo se agrega? | |
| ¿Qué **dos** cosas trae este campo que el del Paso 2 no tenía? | |

```bash
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v2-compatible.avsc
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido-v2-compatible.avsc
curl -s http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions
```

| Hueco | Lo que salió |
|---|---|
| `is_compatible` | |
| `version` del registro nuevo | |
| Lista de versiones del subject | |

**La pregunta del paso:** la v1 sigue en la lista. ¿Qué se rompería si alguien
la borrara para «limpiar»?

---

## Cierre · Las tres preguntas del laboratorio

**1 · ¿Qué tenía de malo el campo `tarjeta_credito`, si era un campo nuevo al
final que no tocaba a ninguno de los seis anteriores?**

**2 · El mismo archivo `pedido-v3-incompatible.avsc` puede pasar la compuerta
sin cambiarle una letra. ¿Qué hay que cambiar para eso, y por qué es una
decisión y no un truco?**

**3 · Si mañana un equipo de SUNAT te pide agregar un campo a un tópico en
producción, ¿cuál es el primer comando que vas a correr, y en qué momento del
despliegue?**

---

> **Lo que sigue** — producir y consumir Avro de verdad, la carga masiva, los
> otros tres modos de compatibilidad, `auto.register.schemas` y el tópico
> `_schemas` están listados en la sección **PARA PROFUNDIZAR** de la guía, con
> su comando completo.
