# Lab 12 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

---

## Parte 1: TLS y certificados

| Pregunta | Respuesta de referencia |
|----------|--------------------------|
| ¿Qué algoritmo y tamaño de llave usa el certificado del broker? | RSA 2048 bits (configurado en `bin/generate-certs.sh`, parámetro `-keyalg RSA -keysize 2048`) |
| ¿Quién es el issuer y quién el subject del certificado del broker 1? | Issuer: `CN=NovaTech-CA-Lab12` (el CA que generamos). Subject: `CN=kafka-broker-1` |
| ¿Por qué el cliente necesita el truststore pero no el keystore en este lab? | El cliente necesita verificar al broker (truststore con CA), pero el broker no le pide certificado al cliente — la identidad del cliente la valida vía SASL, no vía TLS. Si fuera mTLS también necesitaría keystore. |
| ¿Qué cambiaría si quisiéramos mTLS? | Generar keystore por cliente, configurar `KAFKA_SSL_CLIENT_AUTH: required` en el broker, y agregar `ssl.keystore.*` a las properties del cliente. |

---

## Parte 2: SASL y autenticación

| Pregunta | Respuesta de referencia |
|----------|--------------------------|
| ¿Cuántos usuarios están definidos en el JAAS server-side? | 3: admin, app1, app2 (más la credencial inter-broker `username/password`, que apunta a `admin`). |
| ¿Qué error apareció al intentar conectar SIN credenciales? | `org.apache.kafka.common.errors.SaslAuthenticationException` o timeout en el handshake. El broker cierra la conexión porque el listener EXTERNAL exige SASL_SSL. |
| ¿Por qué `User:ANONYMOUS` está en super.users? | El listener INTERNAL es PLAINTEXT (sin SASL). Todas las conexiones inter-broker se identifican como `User:ANONYMOUS`. Sin tenerlo en super.users, las ACLs rechazarían la replicación inter-broker. |
| ¿En qué contexto usarías SCRAM en lugar de PLAIN? | Siempre en producción. PLAIN guarda las passwords en texto plano en el JAAS y las transmite (aunque cifradas por TLS, basta que alguien lea el JAAS). SCRAM hashea la password con salt antes de enviarla. |

---

## Parte 3: ACLs y autorización

| Pregunta | Respuesta de referencia |
|----------|--------------------------|
| Salida abreviada de `kafka-cli/list-acls.sh`: | 3 bloques: `User:app1` con producer+consumer en publico y confidencial; `User:app2` con consumer en publico únicamente. |
| ¿Qué error mostró `app2` al intentar leer el confidencial? | `TopicAuthorizationException: Not authorized to access topics: [novatech.lab12.confidencial]` |
| Diferencia entre `SaslAuthenticationException` y `TopicAuthorizationException` | La primera = falló la **identidad** (sin credenciales o credenciales malas). La segunda = la identidad fue OK pero el authorizer no tiene una ACL que permita la operación. |
| Comando para dar acceso a un nuevo `app3` solo de lectura sobre `novatech.lab12.publico` | `kafka-acls --bootstrap-server kafka-broker-1:9092 --command-config admin.properties --add --allow-principal User:app3 --consumer --topic novatech.lab12.publico --group '*'` |

---

## Parte 4: min.insync.replicas

| Escenario | ¿Funcionó produce? | Razón |
|-----------|---------------------|-------|
| 3 brokers vivos | Sí | ISR=3, supera min.ISR=2 |
| 2 brokers vivos, broker-3 caído | Sí | ISR=2, exactamente igual a min.ISR. Cumple |
| 1 broker vivo, broker-2 y broker-3 caídos | No | ISR=1 < min.ISR=2. `NotEnoughReplicasException` |

| Pregunta | Respuesta de referencia |
|----------|--------------------------|
| ¿Qué min.ISR usarías con RF=5? | min.ISR=3 (sigue la regla `RF = min.ISR + 1` adaptada: tolera 2 fallos simultáneos manteniendo durabilidad mayoritaria). En clusters críticos donde "quórum" matters. |
| ¿Perdiste datos en algún momento al detener brokers? | No. El cluster prefiere bloquear nuevas escrituras (`NotEnoughReplicasException`) antes que comprometer durabilidad. Los mensajes ya escritos siguen replicados en los brokers vivos. |

---

## Parte 5: RBAC

| Pregunta | Respuesta de referencia |
|----------|--------------------------|
| ¿En qué se diferencia un role binding de RBAC de una ACL nativa? | El role binding asigna un rol predefinido (DeveloperRead, ResourceOwner, etc.) que ya empaqueta operaciones; la ACL es atómica (Read, Write, Describe) y debes componerla manualmente. RBAC además acepta `Group:` y se enchufa al directorio corporativo. |
| ¿Qué problema operacional resuelve RBAC que ACLs no resuelven a escala? | Onboarding/offboarding de usuarios: un cambio en LDAP propaga permisos automáticamente. Con ACLs nativas hay que tocar cada cluster manualmente. También: cobertura unificada Kafka + Schema Registry + Connect + ksqlDB. |
| ¿Justificarías RBAC en un cluster con 3 apps y 2 devs? | No. ACLs + IaC (Terraform o un repo con scripts `kafka-acls`) cubre. RBAC es licencia paga y plomería extra; tiene sentido a partir de decenas de devs / múltiples clusters / compliance. |

---

## Parte 6: Capstone integrador

### Desafío 1 — pipeline Connect → Kafka

Salida típica: el último pedido aparece en el topic con offset N+1, generalmente en partición 0 o 1 (depende del round-robin si no hay key). Connector debe estar `RUNNING` con tasks `RUNNING`.

### Desafío 2 — JOIN en ksqlDB

- El STREAM derivado se crea sin errores siempre que las particiones de origen y la TABLE estén co-particionadas.
- Particiones de `pedidos_enriquecidos`: 3 (heredadas).
- Condición del JOIN: co-particionamiento — mismo número de particiones en el STREAM origen y la TABLE, y la misma key.

### Desafío 3 — observabilidad en Grafana

Consumer groups esperados: el del Sink connector (Lab 09), el de ksqlDB (Lab 10) y los exploradores manuales con `console-consumer`. El group con mayor lag suele ser el del Sink si lo detuviste recientemente. Métrica para broker no disponible: `up{job="kafka-jmx"}` o el conteo de partitions en `kafka_server_replicamanager_underreplicatedpartitions` (si el dashboard la incluye).

### Desafío 4 — diseño seguro

| Componente | Respuesta de referencia |
|------------|--------------------------|
| Lab 09 (Connect + PostgreSQL) | Connect autenticado al broker vía SASL_SSL con su propio user `connect-user`. ACLs sobre los topics que produce/consume y sobre `connect-configs`, `connect-offsets`, `connect-status`. PostgreSQL con TLS en su lado y user dedicado de solo lectura para el JDBC source. |
| Lab 10 (Schema Registry + ksqlDB) | Schema Registry con HTTPS y autenticación (basic auth o mTLS). ksqlDB con SASL_SSL al broker, su propio principal con ACLs sobre topics que crea y consume, incluyendo prefijos `_confluent-ksql-*`. |
| Lab 11 (Prometheus + JMX) | JMX exporter sirviendo via HTTPS con auth básica. Prometheus scrapeando con credenciales. Grafana con SSO/LDAP en lugar de admin/admin. |
| Cluster en general | TLS en TODOS los listeners (incluido controller). SASL/SCRAM en lugar de PLAIN. mTLS para inter-broker. Super.users acotado a 1 admin humano + cuentas de servicio justificadas. Rotación de certs automatizada. |

### Desafío 5 (opcional)

Si lo logró: `docker network connect novatech-lab09-net ksqldb-server` y luego en ksqlDB usar bootstrap `kafka-broker-1:29092` (los nombres de host de la red Lab 09). Verificable con `SHOW STREAMS;` y un `CREATE STREAM` apuntando al topic original.

---

## Reflexión final

Las respuestas son personales, pero patrones esperables:
- Lab más difícil suele ser el 06 (transacciones) o el 11 (JMX rules / dashboards).
- Concepto que más cuesta: idempotencia + transacciones, o la diferencia AuthN/AuthZ.
- Prioridades para producción: replicación adecuada, monitoreo (lag, ISR, under-replicated), backups/disaster recovery, auth + auditoría.
