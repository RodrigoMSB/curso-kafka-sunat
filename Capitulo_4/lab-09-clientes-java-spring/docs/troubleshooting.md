# Troubleshooting - Lab 09 (SUNAT)

## Problemas comunes

### 1. `mvn compile` falla al descargar dependencias

**Causa**: sin internet, o una versión que no resuelve.
**Solución**: verificar conexión. Si una versión falla:
- `spring-boot-starter-parent`: si `4.1.0` no resuelve, usar `4.0.6`.
- `tools.jackson:jackson-bom`: usar la última 3.x disponible.
- `kafka-clients`: `4.2.1` (línea Kafka 4.2 del broker).

### 2. El cliente no conecta a Kafka (timeout / connection refused)

**Causa**: el clúster no está arriba, o el cliente apunta mal.
**Solución**: confirmar `bin/start-lab.sh` ejecutado y los 3 brokers healthy. Los clientes usan `localhost:9092,localhost:9093,localhost:9094` (listener EXTERNAL).

### 3. El consumidor no recibe nada

**Causa**: arrancó después de producir y `auto.offset.reset` no aplica como esperas, o grupo distinto.
**Solución**: el código usa `auto.offset.reset=earliest`; si ya consumiste con ese grupo, los offsets quedaron comprometidos. Usa un `group.id` nuevo (argumento de `ConsumidorApp`) para releer desde el principio.

### 4. Spring: el `@KafkaListener` no escucha

**Causa**: falta `@EnableKafka` o la app no terminó de arrancar.
**Solución**: `KafkaConfig` ya incluye `@EnableKafka`. Espera a que la app reporte el arranque completo antes de hacer el POST.

### 5. Spring: error de deserialización por "trusted packages" / tipo

**Causa**: headers de tipo activos sin paquete confiable.
**Solución**: el productor está configurado con `ADD_TYPE_INFO_HEADERS=false` y el consumidor usa tipo destino fijo (`Pedido`). Si modificaste eso, restablécelo o agrega el paquete a trusted packages.

### 6. Puerto 8081 ocupado (Spring)

**Solución**: cambia `server.port` en `cliente-spring/src/main/resources/application.yml`.

### 7. `mvn exec:java` no encuentra la clase

**Causa**: no compilaste antes.
**Solución**: usa `mvn -q compile exec:java -Dexec.mainClass="..."` (compila y ejecuta).

---

*Troubleshooting - Lab 09 (SUNAT)*
