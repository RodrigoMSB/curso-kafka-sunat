# Lab 02: Validación de quórum y prueba de resiliencia

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 2 - KRaft: metadatos, quorum y resiliencia  
**Duración estimada**: ~60 minutos

---

## Contexto narrativo

NovaTech necesita estar seguro de que su clúster KRaft sobrevive a la caída de un controlador. El equipo de infraestructura te pide validar el estado del quorum con `kafka-metadata-quorum` y ejecutar una prueba de resiliencia real: apagar el controlador líder y verificar que el quorum reelige uno nuevo sin perder el clúster, paso por paso, **sin usar un docker-compose pre-hecho**.

Tu misión:
1. Empezar con un broker mínimo
2. Expandir a 3 brokers con quorum KRaft
3. Validar que el clúster está sano usando solo CLI

---

## ¿Qué vas a aprender?

- La estructura interna de las imágenes Confluent (qué binarios trae, dónde viven)
- Cómo se configura un broker Kafka en modo KRaft (sin ZooKeeper)
- Cómo se inicializa el almacenamiento con `kafka-storage format`
- Cómo se configura el quorum de controladores con `controller.quorum.voters`
- Cómo se valida el estado del clúster con `kafka-metadata-quorum`
- Cómo separar listeners internos de externos (desafío)

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM asignada a Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094 |
| Otro clúster Kafka detenido | Sí |
| Imagen Docker | `confluentinc/cp-kafka:8.2.0` |

---

## Inicio rápido

```bash
# 1. Asegurar que no haya otro clúster Kafka corriendo en los mismos puertos
# (desde sus carpetas: bin/stop-lab.sh)

# 2. Dar permisos de ejecución a los scripts del lab
chmod +x bin/*.sh kafka-cli/*.sh

# 3. Abre la primera guía
# guia/01-anatomia-imagen.md
```

A diferencia de los Labs anteriores, **este lab NO tiene un `start-lab.sh` único**. El alumno levanta los componentes paso a paso siguiendo las guías.

---

## Estructura del laboratorio

```
lab-02-validacion-quorum-resiliencia/
├── README.md                  # Este archivo
├── mi-cluster/                # ← AQUÍ CONSTRUIRÁS TUS ARCHIVOS
├── plantillas/                # Esqueletos comentados con TODOs
├── bin/                       # Scripts de validación
├── kafka-cli/                 # Wrappers para tareas específicas
├── guia/                      # 5 guías progresivas
├── plantillas/reporte-entregable.md
├── soluciones/                # Soluciones de referencia
└── docs/                      # Notas instructor, troubleshooting, rúbrica
```

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Inspeccionar imagen Confluent | `kafka-cli/inspect-image.sh` |
| Generar CLUSTER_ID | `kafka-cli/generate-cluster-id.sh` |
| Formatear storage de un broker | `kafka-cli/format-storage.sh <NOMBRE_CONTAINER>` |
| Verificar storage formateado | `bin/verify-storage.sh <NOMBRE_CONTAINER>` |
| Verificar quorum KRaft | `bin/check-quorum.sh` |
| Detener mi-cluster | `bin/stop-mi-cluster.sh` |
| Reset (borra TODO) | `bin/reset-mi-cluster.sh` |

---

## Entregables

1. **`mi-cluster/docker-compose.yml`**: el archivo final con los 3 brokers configurados
2. **`mi-cluster/.env`**: variables de entorno utilizadas
3. **`plantillas/reporte-entregable.md` completado**: con todas las preguntas respondidas

---

## Tecnologías utilizadas

- Apache Kafka 4.2 (modo KRaft, sin ZooKeeper) — vía `confluentinc/cp-kafka:8.2.0`
- Bash scripts
- Docker & Docker Compose v2

---

*Lab 02 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
