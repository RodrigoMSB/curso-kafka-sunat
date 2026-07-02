# Lab 14: Capstone — Resiliencia y seguridad

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 4 - Avanzado, ecosistema, HA/DR y seguridad  
**Duración estimada**: ~90 minutos

---

## Contexto narrativo

Es el último lab. NovaTech Logistics lleva el clúster a producción, y producción significa dos cosas que hasta ahora no exigíamos: **seguridad** (nadie habla en claro, nadie lee lo que no le toca) y **resiliencia** (que la caída de un servidor no se traduzca en pérdida de pedidos ni en corte de servicio).

El CTO te plantea el cierre:
*"Quiero ver, en una sola corrida, que el clúster cifra, autentica, autoriza, y que si pierdo un broker en plena operación no pierdo un solo pedido. Y quiero poder repetirlo a mano para entender cada pieza."*

Tu misión: configurar TLS + SASL + ACLs, y ejecutar un flujo end-to-end con simulación de fallo y recuperación — primero a mano, luego automatizado.

---

## Lo que vas a hacer

| # | Parte | Foco |
|---|-------|------|
| 1 | TLS y certificados | Cifrado en tránsito, PKI propia |
| 2 | SASL y autenticación | Identidad de los clientes (admin/app1/app2) |
| 3 | ACLs y autorización | Quién puede leer/escribir qué |
| 4 | min.insync.replicas | Durabilidad bajo fallo (acks=all) |
| 5 | Simulación de fallo y recuperación | Failover de broker sin pérdida |
| 6 | Capstone automatizado | Todo el flujo en una corrida (`run-capstone.sh`) |

---

## Stack

| Servicio | Imagen | Puerto |
|----------|--------|--------|
| kafka-broker-1/2/3 | confluentinc/cp-kafka:8.2.0 (KRaft) | 9092/9093/9094 (SASL_SSL) |
| Kafbat UI | ghcr.io/kafbat/kafka-ui:latest | 8090 |
| cli-client | confluentinc/cp-kafka:8.2.0 | — |

Listeners por broker: `INTERNAL` (PLAINTEXT, inter-broker + UI) y `EXTERNAL` (SASL_SSL, clientes). `min.insync.replicas=2`, RF=3.

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x, 6 GB a Docker |
| Disco libre | 10 GB |
| Puertos libres | 9092-9094, 8090 |
| `keytool`/`openssl` (los usa generate-certs) | en la imagen cp-kafka |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

`start-lab.sh` genera los certificados, levanta el clúster seguro, crea los tópicos y las ACLs. Luego abre `guia/01-tls-y-certificados.md`.

Para el cierre integrador automático: `bin/run-capstone.sh`.

---

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.

*Lab 14 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
