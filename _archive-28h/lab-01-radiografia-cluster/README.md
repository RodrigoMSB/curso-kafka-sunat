# Lab 01: Radiografía de un clúster Kafka vivo

**Curso**: Administración de Apache Kafka con Confluent Platform  
**Capítulo**: 1 - Fundamentos de Apache Kafka  
**Posición**: Post ítem 3  
**Duración estimada**: 2 horas

---

## Contexto narrativo

Bienvenido a **NovaTech Logistics**, una empresa de logística en tiempo real que gestiona flotas de vehículos, pedidos, sensores IoT y notificaciones a clientes.

Acabas de incorporarte como **ingeniero de plataforma**. Tu primera misión: entender el clúster Kafka que gestiona la telemetría GPS de la flota antes de tocar cualquier cosa. Observar, mapear y documentar.

## ¿Qué vas a hacer?

1. **Explorar** un clúster Kafka con 3 brokers ya operando en modo KRaft
2. **Observar** datos GPS en vivo fluyendo por el sistema
3. **Mapear** la arquitectura: brokers, particiones, líderes, réplicas
4. **Simular** la caída de un broker y observar la tolerancia a fallos
5. **Documentar** tus hallazgos en un reporte estructurado

---

## Prerrequisitos técnicos

| Requisito | Mínimo | Recomendado |
|-----------|--------|-------------|
| Docker Desktop | v4.x | Última versión |
| Docker Compose | v2.x | v2.20+ |
| RAM asignada a Docker | 6 GB | 8 GB |
| Puertos libres | 9092, 9093, 9094, 8090 | |
| Sistema operativo | macOS, Linux, Windows (WSL2) | |
| Navegador web | Cualquier navegador moderno | Chrome o Firefox |

### Verificar prerrequisitos

```bash
docker --version          # Docker Engine 20+
docker compose version    # Docker Compose v2.x
```

---

## ¿Por qué usamos Docker y no instalamos Kafka directamente?

Esta es una pregunta válida en un curso de administración de Kafka. La respuesta corta: **Kafka sí se instala, solo que dentro de contenedores**. Vamos a detallarlo.

### Kafka está instalado de verdad

Las imágenes oficiales de Confluent Platform (`confluentinc/cp-kafka`) traen una instalación completa de Apache Kafka 4.2, Java 21 (Temurin) y todas las herramientas CLI (`kafka-topics`, `kafka-console-producer`, `kafka-consumer-groups`, `kafka-metadata-quorum`, etc.) preinstaladas y listas para usar. Cuando ejecutas `docker exec kafka-broker-1 kafka-topics ...`, estás corriendo el binario real de Kafka dentro del contenedor.

### Por qué Docker simplifica el curso

En vez de gastar horas de clase instalando Java, configurando `JAVA_HOME`, descargando el tarball de Kafka, ajustando rutas y resolviendo las inconsistencias que aparecen entre macOS, Linux y Windows, un solo comando levanta todo el entorno:

```bash
docker compose up -d
```

Esto elimina fricción y nos permite enfocar el tiempo en lo que importa: **entender cómo funciona Kafka**, no en configurar JVMs.

### Operas Kafka de verdad

Los scripts en `kafka-cli/` ejecutan `docker exec` contra los contenedores donde vive Kafka. Es exactamente equivalente a hacer SSH a un servidor con Kafka instalado y ejecutar los mismos comandos. Los comandos, las flags, los mensajes de error y la salida son idénticos a los que verías en una instalación tradicional.

### Analogía

Docker es como un edificio de departamentos amoblados. No instalas los muebles en tu casa; entras al departamento que ya los tiene. Pero los muebles están ahí, son reales, los usas y los tocas. Cuando el curso termine, tendrás la misma soltura con las herramientas que si hubieras instalado todo a mano.

### ¿Y después?

En el **Capítulo 2** del curso estudiaremos en detalle cómo se configura cada componente: `server.properties`, listeners, storage, memoria JVM, autenticación, etc. Entenderás exactamente qué hay dentro de esos contenedores y sabrías reproducirlo en una máquina real sin Docker si tuvieras que hacerlo.

---

## Inicio rápido

```bash
# 1. Dar permisos de ejecución a los scripts
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh

# 2. Iniciar el laboratorio
bin/start-lab.sh

# 3. Abrir la guía de exploración
# guia/01-exploracion-cluster.md
```

---

## Estructura del laboratorio

```
lab-01-radiografia-cluster/
├── README.md                    # Este archivo
├── infra/                       # Infraestructura Docker
│   ├── docker-compose.yml       # Clúster Kafka + Kafbat UI + Productor GPS
│   ├── .env                     # Variables de configuración
│   └── scripts/
│       ├── init-topics.sh       # Creación de tópicos
│       └── gps-data-generator.sh # Generador de datos GPS
├── bin/                         # Scripts de gestión del laboratorio
│   ├── start-lab.sh             # Iniciar todo el entorno
│   ├── stop-lab.sh              # Detener (preserva datos)
│   ├── reset-lab.sh             # Reiniciar (elimina todo)
│   ├── explore-cluster.sh       # Diagnóstico completo del clúster
│   ├── kill-broker.sh           # Simular caída de un broker
│   └── revive-broker.sh         # Recuperar broker caído
├── kafka-cli/                   # Wrappers de comandos Kafka CLI
│   ├── describe-topics.sh       # Describir tópico GPS
│   ├── list-topics.sh           # Listar tópicos
│   ├── check-quorum.sh          # Estado del quorum KRaft
│   ├── consume-gps.sh           # Consumir mensajes GPS
│   ├── check-consumer-groups.sh # Grupos de consumidores
│   └── cluster-status.sh        # Estado de replicación
├── guia/                        # Guías paso a paso
│   ├── 01-exploracion-cluster.md
│   ├── 02-mapeo-arquitectonico.md
│   ├── 03-tolerancia-fallos.md
│   └── 04-desafio-extra.md
├── plantillas/                  # Plantillas para el alumno
│   ├── diagrama-cluster-blanco.drawio
│   └── reporte-entregable.md
├── soluciones/                  # Solo para el instructor
│   ├── reporte-resuelto.md
│   └── respuestas-desafio.md
└── docs/
    └── troubleshooting.md
```

---

## Flujo del laboratorio

Sigue las guías en orden:

| Paso | Guía | Descripción | Duración |
|------|------|-------------|----------|
| 1 | [Exploración del clúster](guia/01-exploracion-cluster.md) | Reconocer componentes, inspeccionar tópicos y quorum | 25 min |
| 2 | [Mapeo arquitectónico](guia/02-mapeo-arquitectonico.md) | Crear diagrama visual de la arquitectura | 20 min |
| 3 | [Tolerancia a fallos](guia/03-tolerancia-fallos.md) | Simular caída y recuperación de un broker | 25 min |
| 4 | [Desafío extra](guia/04-desafio-extra.md) | Retos opcionales para profundizar (bonus) | 15 min |

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar laboratorio | `bin/start-lab.sh` |
| Detener laboratorio | `bin/stop-lab.sh` |
| Reiniciar laboratorio | `bin/reset-lab.sh` |
| Explorar clúster | `bin/explore-cluster.sh` |
| Tumbar broker N | `bin/kill-broker.sh <1\|2\|3>` |
| Revivir broker N | `bin/revive-broker.sh <1\|2\|3>` |
| Ver datos GPS en vivo | `kafka-cli/consume-gps.sh` |
| Ver histórico GPS | `kafka-cli/consume-gps.sh --history` |
| Kafbat UI | http://localhost:8090 |

---

## Entregables

1. **Reporte completado**: `plantillas/reporte-entregable.md` con todas las secciones llenas
2. **Diagrama del clúster**: Archivo draw.io completado o foto del diagrama en papel

---

## Detener y reiniciar

```bash
# Detener sin perder datos (puedes reanudar después)
bin/stop-lab.sh

# Reiniciar desde cero (elimina todos los datos)
bin/reset-lab.sh
```

---

## Problemas frecuentes

Consulta la [guía de troubleshooting](docs/troubleshooting.md) si encuentras problemas.

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0` (Confluent Platform 8.2)
- Kafbat UI — interfaz web open-source para explorar el clúster (vía `ghcr.io/kafbat/kafka-ui`)
- Bash scripts
- Docker & Docker Compose v2

> **Nota sobre la UI**: En este lab usamos Kafbat UI por su simplicidad y velocidad de arranque. Confluent Control Center se introduce en el Capítulo 3 del curso, donde se monta junto a Prometheus y Alertmanager como corresponde a un entorno productivo.

---

*Lab 01 - Curso de Administración de Apache Kafka con Confluent Platform*
