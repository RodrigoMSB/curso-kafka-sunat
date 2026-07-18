# Reporte del Lab 14 — Capstone: Resiliencia y seguridad

**Alumno**: _______________   **Fecha**: ___________

---

## Parte 1: TLS y certificados

| Pregunta | Respuesta |
|----------|-----------|
| ¿Quién firmó el cert de broker-1? | |
| ¿Qué SANs (Subject Alternative Names) tiene? | |
| ¿Cuál es el Issuer? | |
| ¿Cuál es el Subject? | |
| ¿Cuándo expira? | |
| ¿Qué listeners tiene el broker? | |
| ¿Cuál usa SASL_SSL? | |
| ¿Cuál es el inter-broker listener? | |
| ¿Por qué no usamos mTLS aquí? | |
| ¿Qué pasaría si la CA expira? | |
| En producción, ¿quién genera y rota los certs? | |

---

## Parte 2: SASL y autenticación

| Pregunta | Respuesta |
|----------|-----------|
| ¿Cuántos usuarios están definidos? | |
| ¿Cuáles son sus passwords? | |
| ¿Qué pasa si agregas un user_app3 al JAAS y reinicias el broker? | |
| ¿Por qué `User:ANONYMOUS` está en super.users? | |
| ¿Qué pasa si saco a `User:admin` de super.users? | |
| ¿Funcionó producir como app1 al topic público? | |
| ¿Qué error apareció al conectar sin credenciales? | |
| ¿Por qué falla? | |
| ¿PLAIN sin TLS es seguro? | |
| ¿Por qué SCRAM es mejor que PLAIN? | |
| ¿Cuándo usarías Kerberos? | |

---

## Parte 3: ACLs y autorización

| Pregunta | Respuesta |
|----------|-----------|
| ¿Cuántas ACLs aparecen? | |
| ¿Qué principals están listados? | |
| ¿Hay alguna ACL sobre `confidencial` para `app2`? | |
| ¿app1 pudo producir? | |
| ¿admin pudo leer? | |
| ¿Qué error mostró el cliente cuando app2 intentó leer el confidencial? | |
| ¿En qué momento del handshake falló? | |
| ¿app2 recibió el mensaje del público? | |
| ¿Por qué SÍ funciona en este caso? | |
| ¿Qué pasaría si cambiamos `allow.everyone.if.no.acl.found` a `true`? | |
| ¿Por qué `super.users` es peligroso si no se controla? | |

---

## Parte 4: min.insync.replicas (durabilidad)

| Pregunta | Respuesta |
|----------|-----------|
| Si tienes RF=5, ¿qué min.ISR usarías? | |
| ¿Qué pasa con `acks=1` si min.ISR=2? | |
| ¿Cuántas réplicas en ISR por partición (clúster sano)? | |
| ¿Funcionó el produce con 2 brokers vivos (min.ISR=2 cumplido)? | |
| ¿Por qué? | |
| ¿Qué error apareció con 1 broker vivo (min.ISR=2 NO cumplido)? | |
| ¿El cliente reintenta o falla rápido? | |
| ¿Vuelve el ISR a 3 al revivir los brokers? | |
| ¿Cuánto tarda? | |
| ¿En qué casos justificarías RF=5? | |
| ¿Qué pasa si un producer usa `acks=1` en un topic con `min.ISR=2`? | |
| Si pierdes 2 brokers de 3 y vuelven al cabo de 5 minutos, ¿perdiste datos? | |

---

## Parte 5: Simulación de fallo y recuperación

| Pregunta | Respuesta |
|----------|-----------|
| ¿Qué broker es líder de la partición 0? | |
| ¿Cuántas réplicas hay en el ISR de cada partición? | |
| ¿Las particiones que lideraba el broker 3 tienen un líder nuevo? | |
| ¿Cuántas réplicas quedan ahora en el ISR? | |
| ¿El clúster sigue respondiendo a comandos? | |
| ¿La producción funcionó con un broker caído? ¿Por qué? | |
| ¿Qué pasaría con `acks=all` si el ISR bajara de 2? | |
| Al volver el broker 3, ¿el ISR regresó a 3? | |
| ¿El conteo de mensajes incluye los de antes Y los de durante el fallo? | |
| ¿Se perdió algún mensaje? | |

---

## Parte 6: Capstone automatizado

| Pregunta | Respuesta |
|----------|-----------|
| ¿El total final fue 20 mensajes? | |
| ¿En qué paso se ve la elección de nuevo líder? | |
| ¿En qué paso se demuestra que no hubo downtime? | |
| ¿Qué ventaja tiene tener este flujo automatizado como runbook? | |
| ¿Qué pasos añadirías para un escenario de DR real (otro sitio)? | |

---

*Lab 14 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
