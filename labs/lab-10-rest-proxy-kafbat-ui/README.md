# Lab 10: REST Proxy

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 4 - Avanzado, ecosistema, HA/DR y seguridad  
**Duración estimada**: ~60 minutos

---

## Contexto narrativo

NovaTech Logistics integra socios externos: un courier que corre sistemas legacy en .NET viejo, un partner que solo tiene scripts bash, y un proveedor cuyo lenguaje no tiene un buen cliente Kafka. Ninguno puede usar una librería nativa, pero **todos hablan HTTP**.

El CTO te dice:
*"No voy a pedirle a cada partner que integre una librería Kafka. Quiero un punto de entrada HTTP: que cualquiera que sepa hacer un `curl` pueda mandar y leer pedidos. Y quiero verlo en una interfaz, no a ciegas."*

Tu misión: desplegar Confluent REST Proxy para exponer Kafka por HTTP, producir y consumir mensajes con `curl`, y explorar el resultado visualmente en Kafbat UI.

---

## ¿Qué vas a aprender?

- Qué es Confluent REST Proxy y cuándo conviene usar HTTP en vez de un cliente nativo
- Cómo producir mensajes a un tópico con un simple POST
- Cómo consumir por HTTP: el ciclo con estado (crear instancia → suscribir → poll → borrar)
- Por qué consumir por HTTP es distinto de producir (estado vs sin estado)
- Cómo HTTP y clientes nativos conviven sobre el mismo tópico
- Cómo explorar tópicos y mensajes en Kafbat UI

---

## Arquitectura del lab

| Servicio | Rol | Puerto |
|----------|-----|--------|
| `kafka-broker-1/2/3` | Clúster KRaft | 9092–9094 |
| `kafka-rest` | Confluent REST Proxy (acceso HTTP) | 8082 |
| `kafbat-ui` | Interfaz web de exploración | 8090 |

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 6 GB |
| Disco libre | 10 GB |
| Puertos libres | 9092, 9093, 9094, 8082, 8090 |
| `curl` instalado | Sí |
| Otro clúster Kafka detenido | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh rest-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

Arranca 3 brokers + REST Proxy + Kafbat, crea el tópico `novatech.lab10.pedidos` y produce 3 mensajes de muestra vía HTTP.

Luego abre `guia/01-que-es-rest-proxy.md`.

---

*Lab 10 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
