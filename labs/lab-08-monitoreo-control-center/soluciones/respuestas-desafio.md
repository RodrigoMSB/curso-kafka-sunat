# Lab 08 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1-2: Comparativa y casos de uso

### Mensaje pedagógico clave

**Kafbat UI y Control Center NO compiten directamente**. Son herramientas para casos de uso distintos:

- **Kafbat UI** = "navegador" del clúster: ver tópicos, mensajes, configs, consumer groups. Lightweight, gratis, rápido.
- **Control Center** = "centro de operaciones": dashboards históricos, alertas, RBAC, integración con Schema Registry y Connect.

### Tabla detallada

| Aspecto | Kafbat UI | Control Center |
|---------|-----------|----------------|
| **Filosofía** | "Browse and inspect" | "Operate and monitor" |
| **Audiencia** | Devs, SREs ágiles | NOC, gerencia, equipo de operaciones |
| **Despliegue** | 1 contenedor, 200 MB | 1 contenedor (1.5 GB), CC Legacy autocontenido |
| **Costo** | Gratis (open source Apache 2.0) | Eval gratis, comercial para producción |
| **Aprendizaje** | <30 min | 1-2 días para dominar |

---

## Reto 3: Limitaciones honestas

### Limitaciones de Kafbat

- **No tiene retención de métricas**: solo muestra "ahora". Si un broker tuvo problema hace 1 hora, no puedes verlo.
- **No tiene alertas**: si nadie está mirando la UI, nadie se entera del problema.
- **No tiene RBAC nativo en versión open**: cualquiera con acceso ve todo.
- **No tiene integración con Schema Registry visual**.

### Limitaciones de Control Center

- **Pesado**: 1.5 GB de imagen, 1-2 GB de RAM en uso normal.
- **Tarda en arrancar**: 60-90 segundos. En desarrollo es molesto.
- **License para producción**: el período de evaluación está bien para POCs y aprender, pero para uso prolongado hay que pagar.
- **Curva de aprendizaje**: la UI es densa, hay muchas pestañas.
- **Dependencia del ecosistema Confluent**: se integra naturalmente con Schema Registry, Connect, ksqlDB, pero NO con herramientas externas de Apache (ej. Kowl, Conduktor).

---

## Reto 4: Decisiones reales

### Empresa de 5 personas

**Kafbat UI**. Razones:
- Gratis
- Rápido de levantar
- Suficiente para "ver qué pasa"
- No necesitas RBAC con 5 personas (todos son trusted)
- Si un broker falla, lo notarán de inmediato sin alertas formales

### Empresa de 500 personas

**Control Center** (probablemente con Kafbat también para devs). Razones:
- RBAC obligatorio (no todos pueden ver todo)
- Alertas automáticas son críticas (nadie está mirando la UI 24/7)
- Dashboards históricos para análisis post-incidente
- Reportes ejecutivos al directorio
- Integración con Schema Registry, Connect, etc.

### Cuándo usar AMBAS

Configuración profesional muy común:
- **Kafbat** instalada en el namespace de "playground"/"sandbox" para que devs experimenten libremente.
- **Control Center** instalada en el namespace de "production" con RBAC estricto, conectada a herramientas de incident management (PagerDuty, Slack).

Esto da:
- Velocidad de desarrollo (Kafbat)
- Robustez de producción (CC)
- Sin compromiso entre ambos

---

## Reflexión final

| Aspecto | Aprendizaje |
|---------|------------|
| **Monitoreo es un sistema, no una UI** | Brokers + tópico de métricas + UI + alertas trabajan juntos |
| **Open source vs Enterprise** | Cada uno tiene su lugar. La gratis no es "peor"; es distinta |
| **Alertas > Dashboards** | Un dashboard sin alertas = nadie se entera de los problemas |
| **Test bajo carga** | Los problemas reales aparecen con carga real, no en clúster vacío |

---

*Soluciones del desafío - Lab 08*
