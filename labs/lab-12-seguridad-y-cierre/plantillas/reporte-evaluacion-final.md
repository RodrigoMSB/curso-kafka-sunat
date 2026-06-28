# Reporte de evaluación final — Lab 12

> **Cómo usar esta plantilla**: copia este archivo a tu carpeta de notas y rellena cada celda. Si una celda dice "(comando)", pega ahí el comando que ejecutaste y la salida abreviada.

**Alumno**: __________
**Fecha**: __________

---

## Parte 1: TLS y certificados

| Pregunta | Respuesta |
|----------|-----------|
| ¿Qué algoritmo y tamaño de llave usa el certificado del broker? | |
| ¿Quién es el issuer y quién el subject del certificado del broker 1? | |
| ¿Por qué el cliente necesita el truststore pero no el keystore en este lab? | |
| ¿Qué cambiaría si quisiéramos mTLS? | |

---

## Parte 2: SASL y autenticación

| Pregunta | Respuesta |
|----------|-----------|
| ¿Cuántos usuarios están definidos en el JAAS server-side? | |
| ¿Qué error apareció al intentar conectar SIN credenciales? | |
| ¿Por qué `User:ANONYMOUS` está en super.users? | |
| ¿En qué contexto usarías SCRAM en lugar de PLAIN? | |

---

## Parte 3: ACLs y autorización

| Pregunta | Respuesta |
|----------|-----------|
| Salida abreviada de `kafka-cli/list-acls.sh`: | |
| ¿Qué error mostró `app2` al intentar leer el confidencial? | |
| Diferencia entre `SaslAuthenticationException` y `TopicAuthorizationException` | |
| Comando para dar acceso a un nuevo `app3` solo de lectura sobre `novatech.lab12.publico` | |

---

## Parte 4: min.insync.replicas

| Escenario | ¿Funcionó produce? | Razón |
|-----------|---------------------|-------|
| 3 brokers vivos | | |
| 2 brokers vivos, broker-3 caído | | |
| 1 broker vivo, broker-2 y broker-3 caídos | | |

| Pregunta | Respuesta |
|----------|-----------|
| ¿Qué min.ISR usarías con RF=5 y por qué? | |
| ¿Perdiste datos en algún momento al detener brokers? | |

---

## Parte 5: RBAC

| Pregunta | Respuesta |
|----------|-----------|
| ¿En qué se diferencia un role binding de RBAC de una ACL nativa? | |
| ¿Qué problema operacional resuelve RBAC que ACLs no resuelven a escala? | |
| ¿Justificarías RBAC en un cluster con 3 apps y 2 devs? | |

---

## Parte 6: Capstone integrador

### Desafío 1 — pipeline Connect → Kafka

| Campo | Valor |
|-------|-------|
| ID del último pedido recibido | |
| Partición a la que cayó | |

### Desafío 2 — JOIN en ksqlDB

| Campo | Valor |
|-------|-------|
| ¿El STREAM derivado se creó? | |
| Particiones del STREAM `pedidos_enriquecidos` | |
| Condición para que el JOIN funcione | |

### Desafío 3 — observabilidad en Grafana

| Campo | Valor |
|-------|-------|
| Consumer groups activos detectados | |
| Group con mayor lag y razón | |
| Métrica para detectar broker no disponible | |

### Desafío 4 — diseño seguro del pipeline

| Componente | Cambio que aplicarías en producción |
|------------|--------------------------------------|
| Lab 09 (Connect + PostgreSQL) | |
| Lab 10 (Schema Registry + ksqlDB) | |
| Lab 11 (Prometheus + JMX) | |
| Cluster en general | |

### Desafío 5 (opcional) — redes Docker conectadas

| Campo | Valor |
|-------|-------|
| ¿Lo intentaste? | |
| Bootstrap servers usados | |
| ¿Funcionó? | |

---

## Reflexión final

| Pregunta | Respuesta |
|----------|-----------|
| Lab más difícil y por qué | |
| Concepto que más costó | |
| Qué priorizarías al llevar Kafka a producción | |
| Qué aprenderás después | |

---

## Auto-evaluación

| Aspecto | 0 | 1 | 2 |
|---------|---|---|---|
| Levanté el cluster con TLS+SASL sin ayuda | | | |
| Diagnostiqué el error de ACL leyendo el mensaje | | | |
| Explico la regla `RF = min.ISR + 1` con un ejemplo | | | |
| Pude completar el capstone | | | |
| Justifico cuándo NO usar RBAC | | | |

(0 = no logrado, 1 = parcial, 2 = sólido)

**Total**: __ / 10
