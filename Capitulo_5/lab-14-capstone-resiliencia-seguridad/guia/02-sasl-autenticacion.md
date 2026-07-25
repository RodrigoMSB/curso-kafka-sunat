# Parte 2: SASL y autenticación

## Objetivo

Entender SASL como mecanismo de autenticación, leer el archivo JAAS del servidor, y configurar properties de cliente.

## Contexto

TLS soluciona la **confidencialidad** (nadie en la red puede leer). Pero no resuelve **identidad**: ¿quién es el cliente que se conecta?

**SASL** (Simple Authentication and Security Layer) es el framework de autenticación de Kafka. Soporta varios mecanismos:

| Mecanismo | Uso típico | Notas |
|-----------|-----------|-------|
| **PLAIN** | Demos, este lab | Credenciales en texto. **Nunca** sin TLS. |
| **SCRAM-SHA-256/512** | Producción small/medium | Hash con salt; los users se crean via `kafka-configs`. |
| **GSSAPI (Kerberos)** | Empresas grandes con AD | Complejo de operar. |
| **OAUTHBEARER** | Cloud / SSO | OIDC/OAuth tokens. |

> **Decisión pedagógica**: en este lab usamos PLAIN porque tiene credenciales en archivo JAAS visible (didáctico). En producción real **NUNCA usar PLAIN sin TLS**, y preferir SCRAM-SHA-256 mínimo.

---

## El archivo JAAS del servidor

Inspecciona `infra/jaas/kafka_server_jaas.conf`:

```conf
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="admin"
    password="admin-secret"
    user_admin="admin-secret"
    user_app1="app1-secret"
    user_app2="app2-secret";
};
```

Estructura:
- **`KafkaServer { ... };`** — sección para el servidor (broker)
- `username/password` — credencial del propio broker para inter-broker auth
- `user_<NAME>="<PASSWORD>"` — usuarios autorizados a conectarse

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos usuarios están definidos? | |
| ¿Cuáles son sus passwords? | |
| ¿Qué pasa si agregas un user_app3 al JAAS y reinicias el broker? | |

---

## Super users

En `docker-compose.yml`:

```yaml
KAFKA_SUPER_USERS: "User:admin;User:ANONYMOUS"
```

Los **super users** bypassan TODAS las ACLs. `User:admin` es nuestro admin. `User:ANONYMOUS` es para conexiones inter-broker en listeners sin SASL (en este lab, INTERNAL).

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué `User:ANONYMOUS` está en super.users? | |
| ¿Qué pasa si saco a `User:admin` de super.users? | |

> **Pista**: sin ANONYMOUS como super user, las conexiones inter-broker (que viajan por listener INTERNAL plaintext sin auth) serían rechazadas por las ACLs y los brokers no podrían replicar entre ellos.

---

## El archivo properties del cliente

Inspecciona `infra/client-properties/app1.properties`:

```properties
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="app1" password="app1-secret";
ssl.truststore.location=/etc/kafka/secrets/kafka.truststore.jks
ssl.truststore.password=changeit
ssl.endpoint.identification.algorithm=
```

| Línea | Propósito |
|-------|-----------|
| `security.protocol=SASL_SSL` | El cliente habla TLS + SASL |
| `sasl.mechanism=PLAIN` | El mecanismo es PLAIN (mismo que el broker) |
| `sasl.jaas.config=...` | JAAS inline (alternativa al archivo separado) |
| `ssl.truststore.*` | Para verificar al broker |
| `ssl.endpoint.identification.algorithm=` | Vacío = no verifica hostname (acepta el cert con CN=kafka-broker-1) |

---

## Actividad 1: Producir como app1 al topic público

```bash
kafka-cli/produce-publico.sh "Mi primer mensaje autenticado"
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Funcionó? | |

---

## Actividad 2: Conectar SIN credenciales (debe fallar)

```bash
kafka-cli/attempt-no-auth.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué error apareció? | |
| ¿Por qué falla? | |

> **Esperado**: timeout o `SaslAuthenticationException`. El listener EXTERNAL exige SASL_SSL; sin credenciales no hay handshake.

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿PLAIN sin TLS es seguro? | |
| ¿Por qué SCRAM es mejor que PLAIN? | |
| ¿Cuándo usarías Kerberos? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| JAAS server-side | Leíste el archivo, identificaste users |
| Super users | Vista la config en compose |
| Client properties | Comprendiste cada línea |
| Auth en acción | Producir CON y SIN credenciales |

---

## Siguiente paso

Continúa con [Parte 3: ACLs y autorización](03-acls-autorizacion.md).
