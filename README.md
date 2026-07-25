# Administración de Confluent Apache Kafka — SUNAT

Curso práctico de administración de Apache Kafka 4.2 sobre Confluent Platform 8.2.0, en modo KRaft
puro (sin ZooKeeper). Diseñado para administradores, ingenieros de infraestructura, SRE, DevOps y
arquitectos que operan plataformas de mensajería en producción.

> **Duración:** 24 horas · **Formato:** 45% teoría / 55% práctica · **Unidades:** 4 · **Laboratorios:** 14
> **Stack:** Kafka 4.2 · Confluent Platform 8.2.0 · KRaft · Java 21 · Docker Compose

---

## Qué contiene este paquete

| Carpeta / archivo | Contenido |
|---|---|
| `Capitulo_1/` | Capítulo conceptual (arquitectura y ecosistema) + práctica de **validación del entorno**. |
| `Capitulo_2..5/` | Los **14 laboratorios** guiados, agrupados por capítulo. Cada lab es autocontenido (guía, solución, plantilla de entrega, infraestructura Docker, scripts y troubleshooting). |
| `tests/` | **Harness de validación** automatizada de los 14 labs + convenciones de test. |
| `validar-todo.sh` | Botón único de validación cross-platform (macOS + Git-Bash/Windows). |
| `docs/adr/` | **Decisiones de arquitectura** registradas (p. ej. ADR-001: sustitución de Landoop por Kafbat UI). |
| `docs/spec/` | **Especificaciones** de trabajo del proyecto (discovery, pulido, higiene, entrega). |
| `auditoria/` | **Auditoría de calidad** clasificada del curso completo. |

---

## Mapa del curso (4 unidades · 14 labs)

**Unidad 1 — Arquitectura, fundamentos y ecosistema**
Mensajería basada en eventos · arquitectura de Kafka 4.2 · componentes de Confluent Platform 8.2.0.

**Unidad 2 — KRaft: metadatos, quórum y resiliencia**
KRaft a fondo · parámetros clave · dimensionamiento del quórum.
Labs: `01-inicializacion-kraft` · `02-validacion-quorum-resiliencia`.

**Unidad 3 — Configuración del clúster, tópicos y rendimiento**
Inicialización de brokers · multi-broker y `advertised.listeners` · operación de tópicos · producción/consumo
CLI · rendimiento (I/O, red, RAM, CPU, SO) · ubicación de réplicas · reconfiguración en caliente.
Labs: `03-configuracion-brokers` · `04-multibroker-advertised-listeners` · `05-operacion-topicos` ·
`06-produccion-consumo-cli` · `07-pruebas-rendimiento` · `08-brokers-en-caliente`.

**Unidad 4 — Avanzado, ecosistema, HA/DR y seguridad**
Escalamiento y tuning · clientes Java y Spring · REST Proxy y exploración visual · Schema Registry ·
ksqlDB · Kafka Connect · observabilidad y alta disponibilidad · capstone de resiliencia y seguridad.
Labs: `09-clientes-java-spring` · `10-rest-proxy-kafbat-ui` · `11-schema-registry` · `12-ksqldb` ·
`13-kafka-connect` · `14-capstone-resiliencia-seguridad`.

> La presentación organiza estos contenidos en **5 capítulos** (parte la Unidad 4 en dos por su
> extensión). El mapeo con las 4 unidades del temario es 1:1 en contenido — ver `docs/spec/`.

---

## Requisitos del entorno

- **Docker** y **Docker Compose** (los labs levantan clústeres reales localmente).
- **Java 21** para los componentes de la plataforma y los labs de clientes.
- Terminal Unix/Linux o **Git-Bash** en Windows.
- Permisos de administrador para ejecutar los entornos de laboratorio.

---

## Cómo empezar

Cada laboratorio es autocontenido y se ejecuta desde su propia carpeta. La estructura estándar de un lab:

```
Capitulo_N/lab-NN-<nombre>/
├── README.md          → punto de entrada del lab (leer primero)
├── guia/              → guía paso a paso para el participante
├── soluciones/        → respuestas modelo (para el instructor)
├── plantillas/        → plantilla de entrega evaluable
├── infra/             → docker-compose + .env del entorno
├── kafka-cli/         → scripts de los comandos del lab
├── bin/               → utilidades (start/stop/reset · 90-test · 95-recuperar)
└── docs/troubleshooting.md
```

Para validar el estado de todos los labs de una vez:

```bash
./validar-todo.sh
```

---

## Estado de calidad

Auditoría del **2026-07-02** sobre los 14 labs + tests + docs (ver `auditoria/`):

- **0 hallazgos críticos** — ningún comando enseñado falla; toda afirmación técnica verificada empíricamente.
- **Harness 14/14 en verde** — validación automatizada de los 14 labs.
- **Cobertura del temario sustancialmente completa.**

---

*Curso desarrollado para Netec · SUNAT · 2026. Stack sobre Apache Kafka 4.2 y Confluent Platform 8.2.0.*
