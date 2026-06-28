# Parte 2: Tour por Control Center

## Objetivo

Recorrer las pestañas principales de Confluent Control Center Legacy 7.9 y entender qué información ofrece cada una.

## Contexto

Control Center es la UI enterprise de Confluent. Es lo que un equipo NOC (Network Operations Center) usa para vigilar un clúster Kafka en producción.

---

## Actividad 1: Cluster Overview

Abre **http://localhost:9021**. En la página inicial:

| Métrica | Valor observado |
|---------|----------------|
| Número de brokers | |
| Número de tópicos (incluyendo internos) | |
| Mensajes/segundo (production rate) | |
| ¿Hay algún warning? | |

> **Pista**: si las métricas aparecen en 0 o N/A los primeros 1-2 minutos, es normal. Las métricas tardan en propagarse desde los brokers vía `_confluent-metrics`.

---

## Actividad 2: Brokers

Click en **Brokers** en el menú lateral.

Para cada broker:

| Broker | Status | Particiones líder | Particiones seguidor | ISR |
|--------|--------|-------------------|----------------------|-----|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál broker es el "Active Controller" del KRaft? | |
| ¿Hay réplicas fuera de sincronía (Out-of-Sync)? | |

---

## Actividad 3: Topics

Click en **Topics**.

Verifica que aparezcan al menos:
- `novatech.fleet.gps` (del productor GPS)
- `novatech.lab08.transactions` (creado por init script)
- `novatech.lab08.alerts` (creado por init script)
- Topics internos: `_confluent-metrics`, `_confluent-controlcenter-*`, `__consumer_offsets`

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos tópicos en total (incluyendo internos)? | |
| ¿Cuántos tópicos `_confluent-*` ves? | |
| Click en `novatech.fleet.gps`: ¿qué métricas muestra? | |

---

## Actividad 4: Consumer Groups

Click en **Consumers**.

Si el productor GPS lleva un rato corriendo, debería haber al menos 1 consumer group automático del propio Control Center.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos consumer groups aparecen? | |
| ¿Hay alguno con lag alto? | |

---

## Actividad 5: Connect y ksqlDB

Estas pestañas existen pero estarán **vacías o deshabilitadas** porque NO desplegamos esos servicios en este lab. Verifica:

| Pestaña | ¿Aparece? | ¿Tiene contenido? |
|---------|-----------|-------------------|
| Connect | | |
| ksqlDB | | |

> **Nota**: en producción real, CC integra todo el ecosistema Confluent en una sola UI. Lo simplificamos para mantener foco en monitoreo de brokers y tópicos.

---

## Actividad 6: Alerts

Click en **Alerts** (puede llamarse "Alert History" en versión Legacy).

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Hay alertas activas ahora? | |
| ¿Qué tipos de "Triggers" pre-definidos trae CC? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál pestaña te parece más útil para el equipo NOC? | |
| ¿Qué información te gustaría ver y NO está? | |
| Comparado con Kafbat UI (http://localhost:8090), ¿qué tiene de más CC? | |

---

## Conclusiones

| Concepto | Lo aprendiste recorriendo... |
|----------|------------------------------|
| Cluster Overview | Vista panorámica de salud del clúster |
| Brokers detail | Estado individual con métricas históricas |
| Topics view | Métricas por tópico, no solo por broker |
| Alerts | Detección automática de problemas |

---

## Siguiente paso

Continúa con [Parte 3: Métricas bajo carga](03-metricas-bajo-carga.md).
