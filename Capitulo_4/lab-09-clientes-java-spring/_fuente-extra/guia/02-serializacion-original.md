# Parte 2: Serialización de objetos

## Objetivo

Entender que Kafka solo mueve bytes, y que el serializer es el contrato entre productor y consumidor.

## Contexto

El productor envía un `Pedido` (un objeto Java), pero Kafka no sabe nada de objetos: solo guarda `byte[]`. El `PedidoSerializer` convierte `Pedido` → bytes JSON; el `PedidoDeserializer` hace el camino inverso. Si los dos no concuerdan, el consumidor lee basura.

---

## Actividad 1: Leer el serializer

Abre `cliente-java/src/main/java/com/novatech/kafka/PedidoSerializer.java`. Fíjate que:
- Implementa `Serializer<Pedido>`.
- Usa un `JsonMapper` de Jackson 3 (`tools.jackson.databind.json.JsonMapper`).
- `serialize()` es, en esencia, `objeto -> byte[]`.

El `PedidoDeserializer` hace lo inverso: `byte[] -> Pedido`.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué Kafka no serializa los objetos por sí mismo? | |
| ¿Qué pasa si el serializer produce un campo que el deserializer no espera? | |

---

## Actividad 2: Ver el mensaje crudo en Kafbat

Con pedidos ya producidos (Parte 1), abre Kafbat en `http://localhost:8090`, entra al tópico `novatech.lab09.pedidos` y mira un mensaje.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El valor del mensaje se ve como JSON legible? | |
| ¿Qué ventaja tiene JSON frente a un formato binario opaco para depurar? | |

---

## Actividad 3: Romper el contrato (experimento)

El serializer y el deserializer deben coincidir. Para verlo: el `PedidoSerializer` produce JSON con los campos del record `Pedido`. Si el consumidor esperara un tipo distinto, fallaría al deserializar.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué decimos que la serialización es un "contrato"? | |
| ¿Qué riesgo hay si productor y consumidor evolucionan el modelo por separado? | |

---

## Siguiente paso

Continúa con [Parte 3: Spring for Apache Kafka](03-spring-kafka.md).
