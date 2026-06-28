# Parte 3: Métricas bajo carga

## Objetivo

Generar carga sintética constante en el tópico `novatech.lab08.transactions` y observar cómo Control Center actualiza sus dashboards en tiempo real.

## Contexto

Las métricas de un clúster ocioso son aburridas. Necesitas carga real para ver throughput, latencia, lag y comportamiento bajo presión. Vamos a generar 200 msg/seg durante 10 minutos.

---

## Actividad 1: Disparar la carga

En **terminal A**:

```bash
kafka-cli/produce-flood.sh 600 200
```

Esto produce 200 msg/seg durante 600 segundos (10 min) al tópico `novatech.lab08.transactions`.

**Mantén el comando corriendo** y abre Control Center en otra ventana.

---

## Actividad 2: Observar en Cluster Overview

Refresca **http://localhost:9021** en la pestaña Cluster Overview.

| Métrica | Valor observado |
|---------|----------------|
| Production rate (msg/seg total) | |
| ¿Coincide aproximadamente con los 200 msg/seg producidos? | |
| Production throughput (MB/seg) | |

> **Pista**: el rate puede aparecer ligeramente menor que 200 al inicio porque está promediando ventanas de tiempo. Espera 1-2 minutos para que se estabilice.

---

## Actividad 3: Métricas por tópico

En Control Center, click en **Topics** > `novatech.lab08.transactions`.

Observa las pestañas:
- **Overview**: gráficos de producción y consumo
- **Messages**: ver mensajes en vivo
- **Configuration**: configs del tópico
- **Schema**: (vacío en este lab)

| Métrica | Valor |
|---------|-------|
| Throughput de producción (msg/seg) | |
| Throughput de consumo (msg/seg) | |
| ¿Hay diferencia entre producción y consumo? ¿Por qué? | |
| Tamaño total en disco | |

---

## Actividad 4: Distribución entre particiones

En la misma pestaña del tópico, busca la sección de particiones.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las 12 particiones reciben mensajes? | |
| ¿La distribución es uniforme o hay particiones "calientes"? | |
| ¿Qué broker es líder de la mayoría de particiones? | |

---

## Actividad 5: Comparación con Kafbat UI

Abre **http://localhost:8090** y compara la misma pestaña de Topics.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las métricas son iguales? | |
| ¿Cuál UI muestra MÁS información histórica? | |
| ¿Cuál es más rápida de navegar? | |

---

## Actividad 6: Métricas de los consumers

¿Hay algún consumer group activo? Lo más probable es que sí, porque el productor GPS y el propio Control Center crean tópicos internos con consumers.

En CC > Consumers:

| Group | Lag total | Estado |
|-------|-----------|--------|
| | | |
| | | |
| | | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué es importante medir tanto producción como consumo? | |
| Si producción > consumo sostenidamente, ¿qué pasaría? | |
| ¿Qué métricas te alertarían "el clúster está saturado"? | |

---

## Conclusiones

| Concepto | Lo aprendiste midiendo... |
|----------|--------------------------|
| Throughput por tópico | Dashboards de CC actualizados |
| Distribución por partición | Vista granular |
| Métricas históricas | CC mantiene historia visible |
| CC vs Kafbat | CC más detallado, Kafbat más ágil |

---

## Cierre

Cuando termines la observación, puedes parar la carga con Ctrl+C en terminal A.

---

## Siguiente paso

Continúa con [Parte 4: Configurar una alerta](04-configurar-alerta.md).
