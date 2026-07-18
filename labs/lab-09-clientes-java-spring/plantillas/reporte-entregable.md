# Reporte del Lab 09: Clientes Java y Spring

**Alumno**: _______________   **Fecha**: ___________

---

## Parte 1: kafka-clients

| Pregunta | Respuesta |
|----------|-----------|
| ¿En qué particiones cayeron los 20 pedidos? | |
| ¿Se respetó el orden dentro de cada partición? | |
| Las 4 propiedades mínimas del productor | |
| ¿Qué hace `acks=all`? | |

---

## Parte 2: Serialización

| Pregunta | Respuesta |
|----------|-----------|
| ¿Por qué Kafka no serializa los objetos solo? | |
| ¿El mensaje se ve como JSON legible en Kafbat? | |
| ¿Por qué la serialización es un "contrato"? | |

---

## Parte 3: Spring Kafka

| Pregunta | Respuesta |
|----------|-----------|
| ¿El `@KafkaListener` recibió el pedido del POST? | |
| ¿Qué hace `KafkaTemplate` que antes hacías a mano? | |
| ¿Dónde se configuran los serializers en Spring? | |

---

## Parte 4: Consumer groups

| Pregunta | Respuesta |
|----------|-----------|
| ¿Cómo se repartieron los 30 pedidos entre 3 instancias? | |
| Al matar una instancia, ¿qué pasó con sus particiones? | |
| ¿Y si levantaras una 4ª instancia con 3 particiones? | |

---

## Desafío

| Pregunta | Respuesta |
|----------|-----------|
| ¿El consumidor Spring recibió los pedidos de la API nativa? | |
| ¿Qué dice eso sobre el formato del mensaje en el tópico? | |

---

*Lab 09 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
