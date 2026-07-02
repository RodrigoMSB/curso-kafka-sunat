# Lab 01 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Anatomía de la imagen Confluent

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Binarios `kafka-*` en `/usr/bin/` | Aproximadamente 30+. Los más relevantes: `kafka-topics`, `kafka-console-producer`, `kafka-console-consumer`, `kafka-consumer-groups`, `kafka-storage`, `kafka-metadata-quorum`, `kafka-broker-api-versions`, `kafka-configs`, `kafka-acls`, etc. |
| Directorio de configs de ejemplo | `/etc/kafka/` con `server.properties`, `broker.properties`, `controller.properties` (en CP 8.2 ya no existe el subdirectorio `kraft/`). En runtime el entrypoint genera `/etc/kafka/kafka.properties` con la config efectiva. |
| Contenido aproximado de `server.properties` | Configuración tipo `process.roles=broker,controller`, `node.id=1`, listeners por defecto, `log.dirs=/tmp/kraft-combined-logs` (será reemplazado por env vars al levantar) |
| Versión de Java | OpenJDK 21 (Temurin 21.0.10 en CP 8.2.0) |

---

## Parte 2: Mi primer broker solitario

| Pregunta | Respuesta esperada |
|----------|-------------------|
| CLUSTER_ID | Valor único generado por `kafka-storage random-uuid`. Ejemplo: `MkU3OEVBNTcwNTJENDM2Qk` |
| Broker sin formatear | Si la imagen Confluent no detecta storage formateado, intenta autoformatear si pasaste CLUSTER_ID por env. Si falla, debes ejecutar `kafka-storage format` manualmente |
| Qué hace `kafka-storage format` | Crea el archivo `meta.properties` en el `log.dirs`, registrando el `cluster.id` y `node.id`. Es como "particionar" el disco para Kafka |
| ¿Por qué RF=1 con 1 broker? | Replication factor mayor al número de brokers vivos genera el error `InvalidReplicationFactorException` porque no hay suficientes brokers para colocar las réplicas |
| Comando para verificar broker vivo | `kafka-broker-api-versions --bootstrap-server kafka-broker:29092` |

---

---

*Solución - Lab 01 (rebanada: inicialización)*
