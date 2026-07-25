# Reporte del Lab 04: Clúster multi-broker y advertised.listeners

**Alumno**: _______________   **Fecha**: ___________

## Parte 1: Listeners separados

**Mapa de listeners por broker:**

| Broker | PLAINTEXT (interno) | CONTROLLER | EXTERNAL (advertised al host) |
|--------|---------------------|------------|-------------------------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

| Pregunta | Respuesta |
|----------|-----------|
| ¿Por qué KRaft necesita un listener CONTROLLER separado? | |
| ¿Qué resuelve tener `INTER_BROKER_LISTENER_NAME` distinto del CONTROLLER? | |
| Si el clúster está en Docker y los clientes en el host, ¿qué listener usa cada comunicación? | |

## Parte 2: Verificación externa

| Pregunta | Respuesta |
|----------|-----------|
| ¿Qué dirección publica el EXTERNAL en `advertised.listeners`? ¿Respondió el puerto 9092 desde el host? | |
| En el primer intento (contenedor por el EXTERNAL): ¿qué conectó y qué falló? | |
| ¿Por qué el mismo `advertised.listeners` es correcto para el host e inservible para ese contenedor? | |
| A un colega que dice "el bootstrap responde, así que Kafka está bien configurado", ¿qué le contestas? | |

---

*Lab 04 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
