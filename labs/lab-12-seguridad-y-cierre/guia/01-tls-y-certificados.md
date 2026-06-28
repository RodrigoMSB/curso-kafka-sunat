# Parte 1: TLS y certificados

## Objetivo

Entender por qué el tráfico Kafka necesita TLS y cómo se configura. Inspeccionar los certificados generados por `generate-certs.sh`.

## Contexto

Recuerda el primer hallazgo del audit del CISO:

> *"Tráfico sin cifrar: producers y consumers envían mensajes en plaintext."*

Sin TLS, **cualquiera con acceso a la red puede leer los mensajes** (incluyendo `admin-secret` viajando como password de SASL/PLAIN). TLS soluciona la confidencialidad.

---

## Conceptos clave

| Concepto | Qué es |
|----------|--------|
| **CA (Certificate Authority)** | Entidad que firma certificados. Aquí creamos una CA "interna" de NovaTech. |
| **Keystore** | Archivo `.jks` con la clave privada + cert del broker. Cada broker tiene el suyo. |
| **Truststore** | Archivo `.jks` con la lista de CAs en las que confío. Lo tienen brokers Y clientes. |
| **mTLS** | Mutual TLS: el broker exige cert del cliente también. Aquí NO usamos mTLS. |

---

## Arquitectura del Lab 12

```
[Cliente CLI]                                       [Broker]
  truststore (CA root)                            keystore (cert firmado por CA)
       │                                                │
       └────────── handshake TLS ───────────────────────┘
       │ Cliente verifica que el cert del broker
       │ esté firmado por una CA en su truststore
       │
       └─ ✓ Cifrado activado
```

**Nuestro Lab usa TLS solo en lado servidor**: el cliente verifica al broker, pero el broker NO exige cert del cliente. La autenticación del cliente la hace SASL (Parte 2).

---

## Actividad 1: Verificar que los certs existen

```bash
ls -la infra/certs/
```

Deberías ver:
- `ca.crt` y `ca.key` (raíz)
- `kafka.truststore.jks` (lo usan TODOS)
- `kafka-broker-1.keystore.jks`, `kafka-broker-2.keystore.jks`, `kafka-broker-3.keystore.jks` (uno por broker)
- `cert-credentials` (archivo con la password)

Si NO existen, ejecuta:
```bash
bin/generate-certs.sh
```

---

## Actividad 2: Inspeccionar el keystore del broker 1

`keytool` no está en el host (es parte del JDK). Lo corremos dentro del mismo contenedor que usa `bin/generate-certs.sh`:

```bash
docker run --rm \
  -v "$(pwd)/infra/certs:/certs" \
  eclipse-temurin:21-jdk \
  keytool -list -v -keystore /certs/kafka-broker-1.keystore.jks -storepass changeit | head -40
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué entries tiene el keystore? (alias) | |
| ¿Quién firmó el cert de broker-1? | |
| ¿Qué SANs (Subject Alternative Names) tiene? | |

> **Pista**: deberías ver 2 entries: `CARoot` (la CA importada) y `kafka-broker-1` (el cert del broker firmado por la CA). Las SANs incluyen `kafka-broker-1` y `localhost` para que el cert valga tanto desde dentro de Docker como desde el host.

---

## Actividad 3: Verificar que el cert es válido

```bash
openssl x509 -in infra/certs/kafka-broker-1.crt -text -noout | head -30
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál es el Issuer? | |
| ¿Cuál es el Subject? | |
| ¿Cuándo expira? | |

---

## Actividad 4: Listener configuration

Inspecciona la config del broker:

```bash
docker inspect kafka-broker-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E "LISTENERS|SECURITY|SSL_KEYSTORE|SSL_TRUSTSTORE"
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué listeners tiene el broker? | |
| ¿Cuál usa SASL_SSL? | |
| ¿Cuál es el inter-broker listener? | |

> **Pista**: 3 listeners. INTERNAL = PLAINTEXT (inter-broker, red Docker), EXTERNAL = SASL_SSL (cliente, host), CONTROLLER = PLAINTEXT (KRaft).

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué no usamos mTLS aquí? | |
| ¿Qué pasaría si la CA expira? | |
| En producción, ¿quién genera y rota los certs? | |

> **Pista**: mTLS agrega complejidad de generar certs cliente. En producción se usan herramientas como cert-manager (Kubernetes) o AWS Certificate Manager para rotación automática.

---

## Conclusiones

| Concepto | Lo aprendiste explorando... |
|----------|----------------------------|
| CA + truststore + keystore | Inspeccionaste los archivos JKS |
| Listener SASL_SSL | Vista en config del broker |
| TLS solo server-side | El cliente NO necesita keystore propio |

---

## Siguiente paso

Continúa con [Parte 2: SASL y autenticación](02-sasl-autenticacion.md).
