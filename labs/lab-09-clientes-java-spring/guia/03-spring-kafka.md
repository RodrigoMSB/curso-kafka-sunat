# Parte 3: Spring for Apache Kafka

## Objetivo

Hacer el mismo flujo de producción y consumo, pero con Spring Kafka, y ver cuánto código desaparece.

## Contexto

Spring Kafka envuelve la API nativa. Para producir usas `KafkaTemplate`; para consumir, anotas un método con `@KafkaListener`. La configuración de serializers vive en `@Bean` (clase `KafkaConfig`), con las clases nuevas de Jackson 3 (`JacksonJsonSerializer`/`JacksonJsonDeserializer`).

---

## Actividad 1: Arrancar la aplicación Spring

```bash
cd cliente-spring
mvn spring-boot:run
```

Al arrancar, el `@KafkaListener` empieza a escuchar `novatech.lab09.pedidos`. Déjalo corriendo.

---

## Actividad 2: Producir vía REST

En otra terminal:

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"pedidoId":"p-1001","cliente":"ACME","producto":"caja","cantidad":3,"monto":1500.0}' \
  http://localhost:8081/api/pedidos
```

Mira la consola de la app Spring: el `@KafkaListener` registra el pedido recibido.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El log del consumidor mostró el pedido que enviaste? | |
| ¿Qué objeto usa `ProductorService` para enviar? | |
| ¿Qué anotación convierte un método en consumidor? | |

---

## Actividad 3: Comparar con el cliente nativo

Vuelve a mirar `cliente-java` (Partes 1-2) y `cliente-spring`.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué hace `KafkaTemplate` que tú hacías a mano en `cliente-java`? | |
| ¿Dónde se configuran los serializers en la versión Spring? | |
| ¿Qué ganas y qué pierdes usando Spring en vez de la API nativa? | |

---

## Siguiente paso

Continúa con [Parte 4: Consumer groups y desafío](04-consumer-groups-y-desafio.md).
