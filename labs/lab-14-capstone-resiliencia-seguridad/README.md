# Lab 12 — Seguridad y evaluación final

> **Capítulo 4, puntos 9 y 10**: Seguridad operativa (TLS + SASL + ACLs + min.ISR + RBAC) y capstone integrador con todo lo aprendido.

## Narrativa NovaTech

Después de 11 labs construyendo el ecosistema de NovaTech Logistics, llega el último: **levar el cluster a producción**. Eso significa: dejar de hablar plaintext, dejar que cualquiera lea cualquier topic, asegurar que un fallo de hardware no se traduzca en pérdida de pedidos, y entender qué pieza de gestión empresarial entra en juego cuando creces.

Cierra con un **capstone** que combina los Labs 09 (Connect), 10 (Schema Registry + ksqlDB) y 11 (observabilidad) en un único pipeline end-to-end.

---

## Lo que vas a hacer

| # | Parte | Tiempo |
|---|-------|--------|
| 1 | TLS y certificados — generar CA, keystores, truststores | 25 min |
| 2 | SASL/PLAIN — autenticación y archivos JAAS | 20 min |
| 3 | ACLs — autorización con StandardAuthorizer | 25 min |
| 4 | `min.insync.replicas` — durabilidad bajo fallos | 30 min |
| 5 | RBAC como concepto (Confluent Enterprise) | 15 min |
| 6 | Capstone integrador con Labs 09 + 10 + 11 | 60 min |

**Total**: ~2.5 - 3 horas.

---

## Stack

| Servicio | Imagen | Puerto |
|----------|--------|--------|
| kafka-broker-1 | confluentinc/cp-kafka:8.2.0 (KRaft) | 9092 (SASL_SSL) |
| kafka-broker-2 | confluentinc/cp-kafka:8.2.0 (KRaft) | 9093 (SASL_SSL) |
| kafka-broker-3 | confluentinc/cp-kafka:8.2.0 (KRaft) | 9094 (SASL_SSL) |
| Kafbat UI | ghcr.io/kafbat/kafka-ui:latest | 8090 |
| cli-client | confluentinc/cp-kafka:8.2.0 (alive container) | — |

3 listeners por broker:
- `INTERNAL` (PLAINTEXT, puerto 29092/29093/29094) — inter-broker + Kafbat UI
- `EXTERNAL` (SASL_SSL, puerto 9092/9093/9094) — clientes
- `CONTROLLER` (PLAINTEXT, puerto 39092/39093/39094) — KRaft quorum

---

## Requisitos previos

- **Docker Desktop** con 8GB RAM mínimo asignado. Es el único requisito del host (no se necesita Java instalado): `keytool` se ejecuta dentro de un contenedor `eclipse-temurin:21-jdk` que `bin/generate-certs.sh` levanta y descarta automáticamente.
- `openssl` disponible en el shell del host (preinstalado en macOS, Linux y Git Bash en Windows).
- Tener completados los Labs 09, 10 y 11 (necesarios para el capstone).
- Disco libre ~5GB (volúmenes Docker).

### Imágenes Docker que se descargan (~ primera ejecución)

- `confluentinc/cp-kafka:8.2.0` (3 brokers + cli-client)
- `ghcr.io/kafbat/kafka-ui:latest`
- `eclipse-temurin:21-jdk` (solo se usa para generar certificados; ~450 MB)

---

## Estructura del lab

```
lab-12-seguridad-y-cierre/
├── README.md                          ← este archivo
├── infra/
│   ├── docker-compose.yml             5 servicios (3 brokers + Kafbat + cli-client)
│   ├── certs/                         (generado por bin/generate-certs.sh)
│   ├── jaas/
│   │   └── kafka_server_jaas.conf     PLAIN + 3 users
│   ├── client-properties/
│   │   ├── admin.properties
│   │   ├── app1.properties
│   │   └── app2.properties
│   └── scripts/
│       ├── init-lab12-topics.sh       crea publico + confidencial
│       └── init-lab12-acls.sh         3 ACLs
├── bin/
│   ├── common.sh
│   ├── generate-certs.sh              CA + keystores + truststore
│   ├── start-lab.sh                   levanta el cluster end-to-end
│   ├── reset-lab.sh                   limpia volúmenes + certs
│   └── stop-lab.sh
├── kafka-cli/
│   ├── produce-publico.sh             como app1
│   ├── produce-confidencial.sh        como app1
│   ├── consume-publico.sh             como app2 (OK)
│   ├── consume-confidencial-app2.sh   como app2 (DEBE FALLAR)
│   ├── consume-confidencial-admin.sh  como admin (super user, OK)
│   ├── list-acls.sh
│   └── attempt-no-auth.sh             sin credenciales (DEBE FALLAR)
├── guia/
│   ├── 01-tls-y-certificados.md
│   ├── 02-sasl-autenticacion.md
│   ├── 03-acls-autorizacion.md
│   ├── 04-min-insync-replicas.md
│   ├── 05-rbac-concepto.md
│   └── 06-capstone-evaluacion-final.md
├── plantillas/
│   └── reporte-evaluacion-final.md    para que el alumno rellene
├── soluciones/
│   ├── reporte-resuelto.md            respuestas modelo
│   └── respuestas-desafio.md          comandos paso a paso del capstone
└── docs/
    └── troubleshooting.md
```

---

## Cómo arrancar

```bash
cd labs/lab-12-seguridad-y-cierre

# Levanta todo (genera certs + arranca cluster + crea topics + carga ACLs)
bin/start-lab.sh

# Verifica que los 3 brokers estén healthy:
docker ps --filter name=kafka-broker --format 'table {{.Names}}\t{{.Status}}'
```

Espera ver `(healthy)` en los 3 brokers (toma ~60-90s la primera vez por la generación de certs).

Después abre Kafbat UI: http://localhost:8090

---

## Flujo de trabajo recomendado

1. Lee `guia/01-tls-y-certificados.md` y completa sus actividades.
2. Lee `guia/02-sasl-autenticacion.md` — aquí prueba `kafka-cli/attempt-no-auth.sh` (debe fallar).
3. Lee `guia/03-acls-autorizacion.md` — prueba que `app2` NO puede leer el confidencial.
4. Lee `guia/04-min-insync-replicas.md` — para el experimento, detén brokers con `docker stop`.
5. Lee `guia/05-rbac-concepto.md` — solo lectura, no se ejecuta.
6. Capstone: copia `plantillas/reporte-evaluacion-final.md` y rellénalo trabajando con los Labs 09/10/11.
7. Compara con `soluciones/reporte-resuelto.md` para auto-corregir.

---

## Detener / limpiar

```bash
bin/stop-lab.sh    # detiene containers, conserva volúmenes y certs
bin/reset-lab.sh   # detiene + borra volúmenes + borra certs (vuelta a cero)
```

---

## Decisiones pedagógicas

Este lab toma 4 atajos respecto a producción real. Es importante que los entiendas para no llevarte conclusiones erradas:

1. **SASL/PLAIN** (no SCRAM): credenciales en texto en JAAS, didáctico pero inseguro fuera de un lab.
2. **TLS server-side** (no mTLS): solo el broker presenta cert. En producción crítica, mTLS para inter-broker.
3. **RBAC como concepto** (no se configura): requiere Confluent Enterprise + MDS + LDAP, fuera del scope.
4. **Kafbat UI sin auth**: para que veas las cosas. En prod va detrás de SSO.

---

## Si te trabas

1. Mira `docs/troubleshooting.md` (errores típicos cubiertos).
2. Reset duro: `bin/reset-lab.sh && bin/start-lab.sh`.
3. Logs: `docker logs kafka-broker-1 2>&1 | tail -50`.

---

## Después de este lab

Has terminado las **28 horas del curso**. Lo que viene depende de ti:

- Certificación: CCDAK (developer) o CCAAK (admin).
- Profundizar: KIP-500 (KRaft), KIP-851 (StandardAuthorizer), Strimzi Operator.
- Llevar Kafka a un proyecto real con lo aprendido.

> *"En Kafka, los datos no se copian: se replican, se ordenan y se conservan. Y eso lo cambia todo."*
