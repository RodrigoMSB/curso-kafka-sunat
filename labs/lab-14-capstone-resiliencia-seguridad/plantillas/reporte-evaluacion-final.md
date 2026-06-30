# Reporte del Lab 14 — Capstone: Resiliencia y seguridad

**Alumno**: _______________   **Fecha**: ___________

---

## Parte 1-3: Seguridad (TLS / SASL / ACLs)

| Pregunta | Respuesta |
|----------|-----------|
| ¿En qué listener va el tráfico de clientes y qué protocolo usa? | |
| ¿Qué usuario es super user y qué implica? | |
| ¿Qué pasó cuando `app2` intentó leer el tópico confidencial? ¿Por qué? | |

---

## Parte 4: Durabilidad (min.insync.replicas)

| Pregunta | Respuesta |
|----------|-----------|
| ¿Qué garantiza `acks=all` con `min.insync.replicas=2`? | |

---

## Parte 5: Failover y recuperación

| Pregunta | Respuesta |
|----------|-----------|
| Líder de la partición 0 antes del fallo | |
| Tras tumbar el broker 3: ¿hubo nuevo líder? ¿cuántas réplicas en ISR? | |
| ¿La producción funcionó durante el fallo? ¿Por qué? | |
| Al recuperar el broker, ¿el ISR volvió a 3? | |
| Total de mensajes al final (¿hubo pérdida?) | |

---

## Parte 6: Capstone automatizado

| Pregunta | Respuesta |
|----------|-----------|
| ¿`run-capstone.sh` terminó con 20 mensajes? | |
| ¿En qué paso se evidencia el failover sin downtime? | |
| ¿Qué añadirías para un DR real entre sitios? | |

---

*Lab 14 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
