# Parte 5: RBAC como concepto (Confluent Enterprise)

## Objetivo

Entender qué aporta **RBAC (Role-Based Access Control)** sobre las ACLs nativas de Kafka, por qué es una capa de Confluent Enterprise (no Apache Kafka), y cuándo justificaría adoptarlo.

> **Honestidad pedagógica**: en este lab **no vas a configurar RBAC**. RBAC vive en Confluent Server (Enterprise) y requiere MDS (Metadata Service) + integración LDAP/OAuth/Kerberos. Configurarlo en un lab Docker tomaría medio día solo de plomería. Lo que sí harás es **leer una config real** y entenderla.

---

## El problema con ACLs nativas

Llevas 3 partes del lab usando ACLs y ya viste sus límites:

| Limitación | Cómo se manifiesta |
|-----------|---------------------|
| Granularidad por **usuario** | Si tienes 50 desarrolladores en el equipo Pagos, necesitas 50 ACLs (o usar un único user compartido) |
| **No hay grupos** nativos | No existe `Group:pagos` — solo `User:X` |
| **No hay roles reutilizables** | "Read on topics matching `pagos.*`" tienes que repetirlo por cada usuario |
| Solo cubre **Kafka topics + groups + cluster** | Schema Registry, Connect, ksqlDB tienen sus propias capas de auth (o ninguna) |
| Auditoría fragmentada | `kafka-acls --list` te dice "qué", no "quién consumió cuándo" |

A escala empresarial (cientos de devs, decenas de equipos, múltiples clusters), ACLs nativas se vuelven ingobernables.

---

## ¿Qué aporta RBAC?

RBAC introduce tres conceptos que no existen en Apache Kafka puro:

### 1. Roles predefinidos

Confluent define un catálogo de roles con permisos atómicos ya armados. Los más usados:

| Rol | Significado |
|-----|-------------|
| `DeveloperRead` | Read + Describe sobre un recurso |
| `DeveloperWrite` | Write + Describe |
| `DeveloperManage` | Crear, alterar, borrar el recurso |
| `ResourceOwner` | Todo lo anterior + asignar roles a otros sobre ese recurso |
| `SystemAdmin` | Administra todo el cluster |
| `UserAdmin` | Gestiona usuarios y role bindings |

Asignas un rol a un principal sobre un recurso ("role binding"), no permisos atómicos.

### 2. Cobertura más allá de Kafka

Un único role binding puede aplicar a:
- Kafka topics, groups, cluster
- Schema Registry subjects
- Connect connectors
- ksqlDB clusters / streams / tables

En ACLs nativas, Schema Registry no tiene autorización (o la tiene por su cuenta). Con RBAC, todo se centraliza.

### 3. Integración con identidades reales (LDAP / SSO / OAuth)

En lugar de `User:app1` (un nombre que viviste en JAAS), RBAC enchufa con el directorio corporativo (Active Directory, Okta, Azure AD). El principal puede ser:
- Un usuario humano del LDAP corporativo
- Un grupo del LDAP (`Group:equipo-pagos`)
- Un service account con OAuth token

Cuando un dev rota de equipo, IT lo cambia de grupo en LDAP y los permisos en Kafka cambian solos.

---

## Cómo se ve un role binding (ejemplo conceptual)

Esto NO se ejecuta en este lab — es solo para que veas la sintaxis:

```bash
confluent iam rbac role-binding create \
  --principal User:rodrigo.silva@empresa.com \
  --role DeveloperRead \
  --resource Topic:pagos.transacciones \
  --kafka-cluster-id lkc-abc123
```

O el equivalente para un grupo LDAP:

```bash
confluent iam rbac role-binding create \
  --principal Group:equipo-pagos \
  --role DeveloperWrite \
  --resource-pattern "Topic:pagos.*" \
  --pattern-type PREFIXED
```

Compáralo con su equivalente "ACL nativa":

```bash
kafka-acls --add \
  --allow-principal User:rodrigo.silva@empresa.com \
  --consumer \
  --topic pagos.transacciones \
  --group '*'
```

| Diferencia clave | Notas |
|------------------|-------|
| ACLs no soportan `Group:...` | RBAC sí |
| ACLs no soportan patrones de email/SSO | RBAC enchufa el directorio |
| ACLs no cubren Schema Registry | RBAC sí |
| ACLs son flat (allow / deny) | RBAC es jerárquico (rol incluye operaciones) |

---

## ¿Cuándo NO usar RBAC?

RBAC es de Confluent Enterprise (licencia paga). Tiene sentido cuando:

| Señal | ¿Vale RBAC? |
|-------|-------------|
| Cluster con 5 apps, 3 devs | No, ACLs sobran |
| Más de 50 desarrolladores | Sí |
| Múltiples clusters (dev/staging/prod) | Sí |
| Compliance/auditoría requeridos por regulador | Sí |
| Already using Confluent Cloud | Ya lo tienes incluido |
| Apache Kafka self-hosted, equipo chico | ACLs + IaC (Terraform) cubre |

---

## Tu opinión

| Pregunta | Tu respuesta |
|----------|-------------|
| Para tu organización, ¿ACLs nativas alcanzan o necesitas RBAC? | |
| ¿Cuál es el principal beneficio operativo de RBAC más allá del catálogo de roles? | |
| ¿Qué problema NO resuelve RBAC que sí persiste? | |

> **Pista** sobre la última: RBAC no resuelve **encriptación de datos en reposo**, **clasificación de datos** ni **DLP** (Data Loss Prevention). Para eso necesitas otras capas.

---

## Resumen de la jornada de seguridad

A esta altura ya cubriste:

| Capa | Pregunta que responde | Mecanismo en este lab |
|------|------------------------|------------------------|
| Confidencialidad en red | "¿Alguien lee el tráfico?" | TLS server-side |
| Identidad | "¿Quién eres?" | SASL/PLAIN |
| Autorización | "¿Qué puedes hacer?" | ACLs + StandardAuthorizer |
| Durabilidad bajo fallos | "¿Pierdo datos si cae un broker?" | RF=3 + min.ISR=2 |
| Gestión empresarial | "¿Cómo escalo esto a 100+ devs?" | RBAC (concepto) |

---

## Siguiente paso

Continúa con [Parte 6: Capstone — evaluación final integradora](06-capstone-evaluacion-final.md).
