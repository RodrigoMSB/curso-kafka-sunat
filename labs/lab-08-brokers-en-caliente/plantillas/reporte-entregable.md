# Reporte del Lab 08: Cambio de configuración de brokers en caliente

**Alumno**: _______________   **Fecha**: ___________

---

## Parte 1: Tipos de configuración

| Pregunta | Respuesta |
|----------|-----------|
| Valor inicial de `num.replica.fetchers` en broker 1 | |
| Origen que reporta (DEFAULT/STATIC/DYNAMIC) | |
| ¿Por qué la config `default` aparece vacía al inicio? | |

---

## Parte 2: Reconfiguración en caliente

| Cambio | ¿Reinició el broker? | Origen tras el cambio |
|--------|----------------------|------------------------|
| `num.replica.fetchers=4` (broker 1) | | |
| `log.retention.ms=3600000` (default) | | |

| Pregunta | Respuesta |
|----------|-----------|
| Error al intentar cambiar `process.roles` | |
| ¿Por qué es read-only? | |

---

## Parte 3: Agregar broker y reasignar

**Distribución de particiones ANTES (3 brokers):**

| Partición | Replicas |
|-----------|----------|
| 0 | |
| ... | |

**Distribución DESPUÉS de reasignar a 4 brokers:**

| Partición | Replicas |
|-----------|----------|
| 0 | |
| ... | |

| Pregunta | Respuesta |
|----------|-----------|
| ¿Falló la producción durante la reasignación? | |
| ¿Por qué no requiere downtime? | |

---

## Parte 4: Quitar broker

| Pregunta | Respuesta |
|----------|-----------|
| ¿El broker 4 quedó sin particiones tras el drenaje? | |
| ¿Por qué drenar antes de apagar? | |
| ¿El quórum se vio afectado? ¿Por qué no? | |

---

## Desafío

| Pregunta | Respuesta |
|----------|-----------|
| ¿Hubo pérdida de mensajes en el ciclo completo? | |
| ¿Cuál fue el paso más lento? | |

---

*Lab 08 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
