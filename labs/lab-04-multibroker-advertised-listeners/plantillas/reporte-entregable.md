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
| ¿Respondió el broker desde fuera de la red? (comando + resultado) | |
| ¿Qué dirección publica tu EXTERNAL en `advertised.listeners`? | |
| Al romperlo (advertised interno): ¿qué error y en qué momento? | |
| ¿Por qué el bootstrap puede funcionar y aun así el cliente fallar? | |

---

*Lab 04 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
