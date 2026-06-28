# Parte 5: Desafío - Kafbat UI vs Control Center

## Objetivo

Comparar lado a lado las dos UIs disponibles en este lab y articular cuándo usar cada una.

## Contexto

Tienes ambas UIs corriendo simultáneamente. Aprovéchalo para hacer una evaluación crítica.

> **Nota**: estamos comparando contra **Confluent Control Center Legacy 7.9.0**. Existe una versión más nueva, **Control Center Next-Gen 2.x**, que se basa en Prometheus + OTLP + Alertmanager y soporta más particiones. Los conceptos de monitoreo son los mismos en ambas versiones; la diferencia es de implementación interna y madurez del setup.

---

## Reto 1: Tabla comparativa

Abre las 2 UIs en pestañas distintas:
- **http://localhost:8090** — Kafbat UI (open source, ~200MB)
- **http://localhost:9021** — Confluent Control Center Legacy 7.9 (enterprise, ~1.5GB)

Llena la tabla con observaciones reales:

| Aspecto | Kafbat UI | Control Center |
|---------|-----------|----------------|
| **Costo** | | |
| **Tamaño imagen** | | |
| **Tiempo de arranque** | | |
| **Métricas en tiempo real** | | |
| **Dashboards históricos** | | |
| **Alertas configurables** | | |
| **RBAC / multi-tenant** | | |
| **Integración Schema Registry** | | |
| **Stream Designer** | | |
| **Consumer lag visual** | | |
| **Producir mensajes desde UI** | | |
| **Curva de aprendizaje** | | |

> **Nota**: algunos features de CC pueden requerir versión licenciada para uso prolongado. Estás usando el período de evaluación.

---

## Reto 2: Casos de uso

Para cada caso, indica cuál UI elegirías y por qué:

| Caso | UI elegida | Razón |
|------|-----------|-------|
| Startup con 1 dev y un solo clúster | | |
| Empresa con 50 clústers y equipo NOC | | |
| Lab de aprendizaje | | |
| Producción crítica con SLA estricto | | |
| Investigación rápida de un mensaje específico | | |
| Reporte ejecutivo mensual del estado del clúster | | |

---

## Reto 3: Limitaciones de cada uno

### De Kafbat UI

| Limitación | Tu observación |
|-----------|----------------|
| Sin métricas históricas (solo "ahora") | |
| Sin alertas configurables | |
| Sin SSO / RBAC en versión open | |
| ¿Otra que detectaste? | |

### De Control Center

| Limitación | Tu observación |
|-----------|----------------|
| Pesado (1.5 GB de imagen, 1-2 GB de RAM) | |
| Curva de aprendizaje más alta | |
| License para uso prolongado | |
| ¿Otra que detectaste? | |

---

## Reto 4: La pregunta del millón

| Pregunta | Tu respuesta |
|----------|-------------|
| Si tu jefe te pide elegir UNA herramienta para tu empresa de 5 personas, ¿cuál eliges? | |
| ¿Y si fueran 500 personas? | |
| ¿Hay algún caso donde usarías AMBAS al mismo tiempo? | |

> **Pista**: muchas empresas usan AMBAS. Kafbat para el equipo de desarrollo (rápido, ágil, gratis), Control Center para el equipo NOC (alertas, dashboards, RBAC). No es excluyente.

---

## Entrega

Documenta tus respuestas en `plantillas/reporte-entregable.md` en la sección del desafío.
