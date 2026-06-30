# Lab 09: Clientes Java y Spring

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 4 - Avanzado, ecosistema, HA/DR y seguridad  
**Duración estimada**: ~60 minutos

---

## Contexto narrativo

El equipo de desarrollo de NovaTech Logistics necesita integrar Kafka en sus aplicaciones Java. El líder técnico quiere que el equipo entienda dos niveles: primero la librería cruda `kafka-clients` (para saber qué pasa por debajo), y luego Spring for Apache Kafka (como construirán los servicios reales). Y todos los mensajes son objetos `Pedido`, no texto plano: hay que manejar la serialización.

El líder técnico te dice:
*"No quiero que el equipo trate a Kafka como una caja negra. Primero que produzcan y consuman con la API nativa, que vean la serialización a mano. Después les muestras cuánto te ahorra Spring. Y quiero ver pedidos de verdad viajando como JSON."*

Tu misión: compilar y correr un productor/consumidor con `kafka-clients`, implementar la serialización de objetos `Pedido`, y luego hacer lo mismo con Spring (KafkaTemplate + @KafkaListener).

---

## ¿Qué vas a aprender?

- Producir y consumir con la librería nativa `kafka-clients`
- La configuración mínima de un cliente Kafka (bootstrap, serializers, grupo, acks)
- Qué es un serializer y por qué es el contrato entre productor y consumidor
- Cómo Spring for Apache Kafka simplifica todo con `KafkaTemplate` y `@KafkaListener`
- Cómo se reparten las particiones entre instancias de un mismo grupo de consumidores

---

## Arquitectura del lab

| Componente | Dónde corre | Detalle |
|------------|-------------|---------|
| Clúster KRaft (3 brokers) + Kafbat | Docker (Fase 1) | `localhost:9092/9093/9094`, UI `:8090` |
| `cliente-java/` | VM (JDK 21 + Maven) | kafka-clients 4.2.1 + Jackson 3 |
| `cliente-spring/` | VM (JDK 21 + Maven) | Spring Boot 4.1 + spring-kafka 4, REST en `:8081` |

Los clientes corren en la VM y se conectan al clúster dockerizado por el listener EXTERNAL (`localhost`).

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| JDK | 21 |
| Maven | 3.9+ |
| `curl` | Sí |
| RAM Docker | 6 GB |
| Puertos libres | 9092-9094, 8090, 8081 |

---

## Inicio rápido

```bash
# 1. Levantar el clúster (Docker)
chmod +x bin/*.sh infra/scripts/*.sh
bin/start-lab.sh

# 2. Verificar que Maven y Java están listos en la VM
java -version   # debe decir 21
mvn -version
```

Luego abre `guia/01-cliente-kafka-clients.md`.

---

*Lab 09 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
