# Parte 1: Cliente con kafka-clients (API nativa)

## Objetivo

Producir y consumir mensajes con la librería cruda `kafka-clients`, entendiendo la configuración mínima de un cliente.

## Contexto

Antes de cualquier framework, así se habla con Kafka desde Java: defines unas propiedades, creas un `KafkaProducer` o `KafkaConsumer`, y envías o haces `poll`. El proyecto `cliente-java/` ya trae ese código.

---

## Actividad 1: Compilar el proyecto

```bash
cd cliente-java
mvn -q compile
```

Si compila sin errores, las dependencias (kafka-clients 4.2.1, Jackson 3) se resolvieron bien.

> Si el primer compile falla por una versión, revisa `pom.xml` (ver `docs/troubleshooting.md`).

---

## Actividad 2: Arrancar el consumidor (déjalo escuchando)

En una terminal:

```bash
mvn -q compile exec:java -Dexec.mainClass="com.novatech.kafka.ConsumidorApp" -Dexec.args="grupo-java-nativo"
```

Queda esperando mensajes. Déjalo abierto.

---

## Actividad 3: Producir desde otra terminal

En una segunda terminal (mismo directorio `cliente-java/`):

```bash
mvn -q compile exec:java -Dexec.mainClass="com.novatech.kafka.ProductorApp" -Dexec.args="20"
```

Envía 20 pedidos. Verás la partición y el offset de cada uno. Mira la primera terminal: el consumidor los recibe.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿En qué particiones cayeron los 20 pedidos? | |
| ¿El consumidor los recibió en el mismo orden dentro de cada partición? | |
| ¿Qué 4 propiedades mínimas configura el productor? (revisa `ProductorApp`) | |
| ¿Qué hace `acks=all`? | |

---

## Siguiente paso

Continúa con [Parte 2: Serialización de objetos](02-serializacion.md).
