# Parte 3: ACLs y autorización

## Objetivo

Entender qué es una ACL, leer la sintaxis de `kafka-acls`, y verificar en vivo cómo Kafka aplica las reglas: `app1` produce/consume el confidencial, `app2` solo lee el público.

## Contexto

Hasta ahora tenemos:
- **TLS** → confidencialidad en la red.
- **SASL** → identidad ("¿quién eres?").

Falta lo último: **autorización** ("¿qué puedes hacer?"). Para eso Kafka usa **ACLs** (Access Control Lists).

Una ACL es una regla del tipo:

> *Permitir / Denegar* al **principal** `User:X`, la **operación** `OP`, sobre el **recurso** `RESOURCE_TYPE:name`, desde el **host** `H`.

Si no hay ninguna ACL que aplique y el broker tiene `allow.everyone.if.no.acl.found=false` → **denegado por defecto**. Esa es nuestra config. Es lo correcto en producción.

---

## El authorizer en KRaft

En `docker-compose.yml`:

```yaml
KAFKA_AUTHORIZER_CLASS_NAME: org.apache.kafka.metadata.authorizer.StandardAuthorizer
KAFKA_ALLOW_EVERYONE_IF_NO_ACL_FOUND: "false"
KAFKA_SUPER_USERS: "User:admin;User:ANONYMOUS"
```

| Línea | Significado |
|-------|-------------|
| `StandardAuthorizer` | Authorizer nativo de KRaft (reemplaza al viejo `AclAuthorizer` de ZooKeeper) |
| `allow.everyone.if.no.acl.found=false` | Si no hay ACL → **denegar**. Whitelist por defecto. |
| `super.users` | `admin` y `ANONYMOUS` bypassan TODAS las ACLs |

> **Importante**: en KRaft las ACLs se persisten en el **metadata log** del controller, no en ZooKeeper. Se replican junto con el resto del estado del cluster.

---

## Sintaxis de `kafka-acls`

Forma general:

```
kafka-acls --bootstrap-server <host:port> \
  --command-config <client.properties> \
  --add | --remove | --list \
  --allow-principal User:<NAME> \
  --operation <OP> \
  --topic <NAME> | --group <NAME> | --cluster
```

| Atajo | Equivale a |
|-------|-----------|
| `--producer` | `--operation Write --operation Describe --operation Create` (sobre topic) |
| `--consumer` | `--operation Read --operation Describe` (sobre topic) + `--operation Read` (sobre group) |

Operaciones más comunes: `Read`, `Write`, `Create`, `Delete`, `Alter`, `Describe`, `ClusterAction`.

Recursos: `--topic`, `--group`, `--cluster`, `--transactional-id`.

---

## Las ACLs que carga este lab

Mira `infra/scripts/init-lab12-acls.sh`. Crea 3 reglas:

| Principal | Recurso | Permisos |
|-----------|---------|----------|
| `User:app1` | topic `novatech.lab12.publico` | producer + consumer |
| `User:app1` | topic `novatech.lab12.confidencial` | producer + consumer |
| `User:app2` | topic `novatech.lab12.publico` | **solo consumer** |

Notar que **NO hay** ACL para `User:app2` sobre `novatech.lab12.confidencial`. Por la regla "deny por defecto", `app2` será **rechazado** al intentar leer el confidencial.

Lista las ACLs vigentes:

```bash
kafka-cli/list-acls.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas ACLs aparecen? | |
| ¿Qué principals están listados? | |
| ¿Hay alguna ACL sobre `confidencial` para `app2`? | |

---

## Actividad 1: app1 produce y consume el confidencial (debe funcionar)

```bash
kafka-cli/produce-confidencial.sh "Datos sensibles desde app1"
```

Y luego, como `admin` (super user, bypasses ACLs):

```bash
kafka-cli/consume-confidencial-admin.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿app1 pudo producir? | |
| ¿admin pudo leer? | |

---

## Actividad 2: app2 intenta leer el confidencial (debe fallar)

```bash
kafka-cli/consume-confidencial-app2.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué error mostró el cliente? | |
| ¿En qué momento del handshake falló? | |

> **Esperado**: `TopicAuthorizationException: Not authorized to access topics: [novatech.lab12.confidencial]`. El handshake SASL pasó (app2 SÍ se autenticó), pero el authorizer rechazó la operación porque no hay ACL.

**Importante**: la diferencia con la Actividad 2 de la Parte 2 (sin credenciales) es clave:
- Sin SASL → `SaslAuthenticationException` (falló la **identidad**).
- Con SASL pero sin ACL → `TopicAuthorizationException` (la identidad fue OK, falló la **autorización**).

---

## Actividad 3: app2 lee el público (debe funcionar)

```bash
kafka-cli/consume-publico.sh
```

(En otra terminal, produce algo desde app1: `kafka-cli/produce-publico.sh "hola desde app1"`.)

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿app2 recibió el mensaje? | |
| ¿Por qué SÍ funciona en este caso? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasaría si cambiamos `allow.everyone.if.no.acl.found` a `true`? | |
| ¿Por qué `super.users` es peligroso si no se controla? | |
| ¿Cómo darías acceso a un nuevo equipo `app3` solo de lectura sobre `novatech.lab12.publico`? Escribe el comando. | |

> **Pista** sobre la última: usa `kafka-acls --add --allow-principal User:app3 --consumer --topic novatech.lab12.publico --group '*'`.

---

## Resumen de lo que demostraste

| Concepto | Lo viste haciendo... |
|----------|----------------------|
| Authorizer en KRaft | Leíste la config en compose |
| Whitelist por defecto | `app2` rechazado sobre confidencial |
| Diferencia AuthN vs AuthZ | Comparaste error sin SASL vs con SASL sin ACL |
| `--producer` / `--consumer` shortcuts | Los aplicaste en init-lab12-acls.sh |
| Super users | `admin` leyó el confidencial sin necesitar ACL explícita |

---

## Siguiente paso

Continúa con [Parte 4: min.insync.replicas y durabilidad](04-min-insync-replicas.md).
