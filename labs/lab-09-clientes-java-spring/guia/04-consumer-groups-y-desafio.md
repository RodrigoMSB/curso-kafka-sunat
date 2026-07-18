# Parte 4: Consumer groups y desafío

## Objetivo

Ver cómo se reparten las particiones entre varias instancias de un mismo grupo de consumidores.

## Contexto

El tópico `novatech.lab09.pedidos` tiene 3 particiones. Si levantas varias instancias del consumidor con el **mismo** `group.id`, Kafka reparte las particiones entre ellas: eso es escalado horizontal del consumo. Usaremos el `cliente-java` para verlo en vivo.

---

## Actividad 1: Tres consumidores, mismo grupo

Abre **tres** terminales en `cliente-java/`. En cada una:

```bash
mvn -q compile exec:java -Dexec.mainClass="com.novatech.kafka.ConsumidorApp" -Dexec.args="grupo-escalado"
```

Las tres usan el mismo grupo `grupo-escalado`. Espera a que se asignen las particiones.

---

## Actividad 2: Producir y observar el reparto

En una cuarta terminal:

```bash
mvn -q compile exec:java -Dexec.mainClass="com.novatech.kafka.ProductorApp" -Dexec.args="30"
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cómo se repartieron los 30 pedidos entre las 3 instancias? | |
| ¿Cada instancia atendió una partición distinta? | |

---

## Actividad 3: Rebalanceo

Mata una de las tres instancias (Ctrl+C) y vuelve a producir 30 pedidos.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasó con las particiones de la instancia que mataste? | |
| ¿Qué pasaría si levantaras una 4ª instancia con 3 particiones? | |

---

## Desafío

Interoperabilidad entre los dos proyectos: produce pedidos con `cliente-java` (`ProductorApp`) y consúmelos con `cliente-spring` (la app con `@KafkaListener` corriendo). Documenta: ¿el consumidor Spring recibió los pedidos producidos por la API nativa? ¿Qué te dice eso sobre el formato del mensaje en el tópico?

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| API nativa kafka-clients | Productor/consumidor con `KafkaProducer`/`KafkaConsumer` |
| Serialización | Implementaste el contrato `Pedido` ↔ JSON bytes |
| Spring Kafka | `KafkaTemplate` + `@KafkaListener` con mucho menos código |
| Consumer groups | Viste el reparto de particiones y el rebalanceo |
| Interoperabilidad | Mensajes nativos consumidos por Spring (y viceversa) |
