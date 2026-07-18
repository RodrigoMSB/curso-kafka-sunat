# Reporte del Lab 02: Validación de quórum y resiliencia

**Alumno**: _______________   **Fecha**: ___________

## Parte 1: Creciendo a 3 brokers

| Pregunta | Respuesta |
|----------|-----------|
| ¿Los 3 contenedores están corriendo? | |
| Si alguno NO arrancó, ¿qué dice `docker logs <nombre>`? | |
| ¿Cuál es el LeaderId? | |
| ¿Aparecen los 3 voters? | |
| ¿Qué LAG tienen los voters? | |
| ¿Cuántas particiones tiene? | |
| ¿Cuántas réplicas tiene cada partición? | |
| ¿Quién es el líder de la partición 0? | |
| ¿Qué brokers tiene en su ISR? | |

## Parte 2: Chequeo de salud y resiliencia

| Pregunta | Respuesta |
|----------|-----------|
| ¿Qué es `LeaderEpoch`? | |
| ¿Qué pasa si el líder muere? ¿Cómo cambian estos valores? | |
| ¿Qué diferencia hay entre `CurrentVoters` y `CurrentObservers`? | |
| ¿Qué significa `Lag` aquí, en el contexto del quorum? | |
| Si un broker tuviera Lag muy alto y `LastCaughtUpTimestamp` antiguo, ¿qué problema indicaría? | |
| ¿Cambió el LeaderId? | |
| ¿Cambió el LeaderEpoch? | |
| ¿Cuántos voters quedan disponibles? | |
| ¿El clúster sigue operativo? | |
| ¿El broker volvió como voter o como observer? | |
| ¿Recuperó su rol de líder? | |
| ¿Por qué crees que se mantiene el nuevo líder en vez de "devolver" el liderazgo? | |

---

*Lab 02 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
