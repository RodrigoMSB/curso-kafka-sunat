# Lab 05: Operación de tópicos

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento  
**Duración estimada**: ~60 minutos

---

## Contexto narrativo

NovaTech tiene un nuevo requerimiento del CTO: **cada tipo de dato del negocio merece su propio tópico con configuración específica**. No todos los datos tienen el mismo perfil:

- **Telemetría GPS**: gran volumen, retención corta
- **Eventos de auditoría**: compliance, retención de 90 días
- **Estado actual de cada vehículo**: solo el último valor importa (compactación)
- **Alertas críticas**: máxima durabilidad

Tu misión: crear cada tópico con la configuración exacta, modificarlos cuando los requerimientos cambien, y demostrar que las configs efectivamente cambian el comportamiento.

---

## ¿Qué vas a aprender?

- Anatomía completa de un tópico (particiones, ISR, configs efectivas)
- Crear tópicos con `--config` (retención, compactación, replicación)
- Modificar tópicos en caliente sin downtime
- Aumentar particiones (y entender por qué no se pueden disminuir)

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| Docker Compose | v2.x |
| RAM Docker | 6 GB |
| Puertos libres | 9092, 9093, 9094, 8090 |
| Otro clúster Kafka detenido | Sí |

---

## Inicio rápido

```bash
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
bin/start-lab.sh
```

Luego abre la guía: [`guia/01-retencion-quien-borro-los-comprobantes.md`](guia/01-retencion-quien-borro-los-comprobantes.md).

---

## Las tres carpetas

| Carpeta | Qué lleva | Para quién |
|---------|-----------|------------|
| `practica/` | `PASOS.md` (el recorrido con los huecos que tú rellenas) y `crear-topicos.sh` con tres valores en blanco | El alumno |
| `solucion/` | `crear-topicos.sh` resuelto y comentado línea por línea, y `SALIDAS.md` con la transcripción de una corrida real | El alumno, **después** de intentarlo |
| `instructor/` | `GUION.md`: qué decir, qué preguntar antes de cada comando, qué sale, qué hacer cuando no sale, y el reloj por bloque | El relator |

> `soluciones/` (con **s** final) es otra cosa y sigue en su sitio: son las
> respuestas de referencia del reporte entregable. `solucion/` es el código
> resuelto de `practica/`.

---

## Comandos principales

| Acción | Comando |
|--------|---------|
| Iniciar lab | `bin/start-lab.sh` |
| Detener lab | `bin/stop-lab.sh` |
| Reset | `bin/reset-lab.sh` |
| Listar tópicos | `kafka-cli/list-topics.sh [--internal]` |
| Crear tópico | `kafka-cli/create-topic.sh <NOMBRE> [opciones]` |
| Describir tópico | `kafka-cli/describe-topic.sh <NOMBRE>` |
| Modificar config | `kafka-cli/alter-topic-config.sh <NOMBRE> --add KEY=VALUE` |
| Modificar particiones | `kafka-cli/alter-topic-partitions.sh <NOMBRE> N` |
| Eliminar tópico | `kafka-cli/delete-topic.sh <NOMBRE>` |
| Producir N mensajes | `kafka-cli/produce-bulk.sh <NOMBRE> N [--key-pattern P]` |
| Kafbat UI | http://localhost:8090 |

---

## Tecnologías

- Apache Kafka 4.2 (KRaft) — `confluentinc/cp-kafka:8.2.0`
- Kafbat UI — `ghcr.io/kafbat/kafka-ui`
- Bash + Docker Compose v2

---

> **¿Te atascaste?** Ejecuta `bin/95-recuperar-lab.sh` y te deja en un estado funcional para seguir la clase.
>
> **Valida tu avance** en cualquier momento: `bin/90-test-lab.sh`.

*Lab 05 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
