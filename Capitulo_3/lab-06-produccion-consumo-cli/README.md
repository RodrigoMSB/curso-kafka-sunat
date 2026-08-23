# Lab 06: Producción y consumo desde CLI

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento  
**Duración estimada**: **20 minutos de dictado en clase** (`instructor/GUION.md`)  
~60 minutos si haces el laboratorio completo por tu cuenta, incluida la sección
*Para profundizar* de la guía

---

## Contexto narrativo

NovaTech Logistics tiene su clúster GPS funcionando. Ahora **el negocio creció** y tres áreas distintas necesitan consumir los datos de la flota:

- 📊 **Dashboard de Operaciones** — necesita ver TODO en tiempo real
- 🚨 **Sistema de Alertas** — necesita procesar cada evento sin perderlo, escalando horizontalmente
- 📈 **Módulo de Reportes Históricos** — necesita re-procesar datos antiguos para analítica

Tu jefe pregunta: *"¿Cómo hacemos que las 3 áreas vean los mismos datos sin pisarse, y cómo reprocesamos datos antiguos cuando haga falta?"*

**Tu misión**: demostrar el modelo pub/sub de Kafka resolviendo este problema con experimentos en vivo.

---

## ¿Qué vas a hacer?

1. **Producir y consumir mensajes manualmente** para entender el log inmutable
2. **Lanzar múltiples consumidores independientes** (modelo broadcast)
3. **Resetear offsets** para "rebobinar el tiempo" y reprocesar mensajes

---

## Prerrequisitos técnicos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM asignada a Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Otro clúster Kafka detenido (los puertos chocan) | Sí |

---

## Inicio rápido

```bash
# 1. Asegurar que no haya otro clúster Kafka corriendo en los mismos puertos
# (si tienes otro lab levantado, detenlo con su bin/stop-lab.sh)

# 2. Dar permisos de ejecución
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh

# 3. Iniciar el laboratorio
bin/start-lab.sh

# 4. Abrir la guía
# guia/01-grupos-y-quien-repartio-el-trabajo.md
```

---

## Estructura del laboratorio

```
lab-06-produccion-consumo-cli/
├── README.md                  # Este archivo
├── infra/
│   ├── docker-compose.yml     # Clúster KRaft de 3 brokers
│   ├── .env
│   └── scripts/
│       └── init-events-topic.sh
├── bin/
│   ├── common.sh
│   ├── start-lab.sh           # Levanta clúster + crea tópico
│   ├── stop-lab.sh
│   └── reset-lab.sh
├── kafka-cli/
│   ├── produce-event.sh       # Produce 1 mensaje
│   ├── consume-event.sh       # Consume sin grupo (broadcast)
│   ├── consume-as-group.sh    # Consume en grupo (escalable)
│   ├── list-groups.sh         # Lista todos los grupos
│   ├── describe-group.sh      # Detalle de un grupo (offsets, lag)
│   └── reset-group.sh         # Resetea offsets a --to-earliest
├── guia/
│   └── 01-grupos-y-quien-repartio-el-trabajo.md
├── practica/
│   └── PASOS.md               # el recorrido con los huecos que rellenas
├── instructor/
│   └── GUION.md               # qué decir, qué preguntar, qué hacer si falla
├── plantillas/
│   └── reporte-entregable.md
├── soluciones/
│   ├── reporte-resuelto.md
│   └── respuestas-desafio.md
└── docs/
    └── troubleshooting.md
```

---

## Las tres carpetas

| Carpeta | Qué lleva | Para quién |
|---------|-----------|------------|
| `practica/` | `PASOS.md`: el recorrido en seco, con los comandos en orden y los huecos que tú rellenas | El alumno |
| `soluciones/` | `SALIDAS.md` con la transcripción de una corrida real y sus controles, y `reporte-resuelto.md` con las respuestas de referencia | El alumno, **después** de intentarlo |
| `instructor/` | `GUION.md`: qué decir, qué preguntar antes de cada comando, qué sale, qué hacer cuando no sale, y el reloj por bloque | El relator |

> **Si vienes del modelo de tres carpetas** (`practica/` · `solucion/` ·
> `instructor/`): aquí **`soluciones/`, en plural, cumple el rol de
> `solucion/`**. No falta ninguna carpeta — es el nombre que usan los catorce
> labs del curso.

> 🔴 **Este lab necesita CUATRO terminales.** Los consumidores se quedan
> corriendo hasta que los cortes con `Ctrl+C`.

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar laboratorio | `bin/start-lab.sh` |
| Detener laboratorio | `bin/stop-lab.sh` |
| Reiniciar laboratorio | `bin/reset-lab.sh` |
| Producir 1 mensaje | `kafka-cli/produce-event.sh "<MENSAJE>"` |
| Producir con clave | `kafka-cli/produce-event.sh --key NVT-1001 "<MENSAJE>"` |
| Consumir sin grupo | `kafka-cli/consume-event.sh [--from-beginning]` |
| Consumir en grupo | `kafka-cli/consume-as-group.sh --group <NOMBRE>` |
| Listar grupos | `kafka-cli/list-groups.sh` |
| Describir grupo | `kafka-cli/describe-group.sh <NOMBRE>` |
| Resetear grupo | `kafka-cli/reset-group.sh <NOMBRE>` |
| Kafbat UI | http://localhost:8090 |

---

## Entregables

1. **Reporte completado**: `plantillas/reporte-entregable.md` con todas las secciones llenas

---

## Problemas frecuentes

Consulta la [guía de troubleshooting](docs/troubleshooting.md) si encuentras problemas.

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft) — vía `confluentinc/cp-kafka:8.2.0`
- Kafbat UI — interfaz web open-source — vía `ghcr.io/kafbat/kafka-ui`
- Bash scripts
- Docker & Docker Compose v2

---

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.
>
> **Valida tu avance** en cualquier momento: `bin/90-test-lab.sh`.

*Lab 06 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
