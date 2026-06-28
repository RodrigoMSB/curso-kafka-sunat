# Reporte del Lab 11: Prometheus + Grafana + tour Confluent Cloud

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Arquitectura de monitoreo

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 3 endpoints JMX Exporter (7071, 7072, 7073) responden? | |
| Tipos de métricas observados (counter, gauge, histogram) | |
| Targets totales en Prometheus | |
| Targets UP en Prometheus | |
| ¿Aparece el dashboard pre-cargado en Grafana? | |

---

## Parte 2: Tour por Grafana

### 4 métricas críticas

| Métrica | Valor inicial |
|---------|--------------|
| Bytes In/Out per second | |
| Request Rate | |
| Under Replicated Partitions | |
| Active Controllers | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos paneles tiene el dashboard? | |
| ¿Qué pasaría si Active Controllers fuera 0? | |
| ¿Y si fuera 2? | |

### Paneles "No data" (si los hay)

| Panel | Posible causa |
|-------|--------------|
| | |
| | |

---

## Parte 3: Métricas bajo carga

### Generación de carga

| Métrica | Valor observado |
|---------|----------------|
| Bytes In total | |
| ¿Coincide con ~40 KB/s esperados? | |
| Distribución uniforme entre brokers | |
| Throughput total (msg/seg) | |

### Experimento de fallo (broker 2 down)

| Métrica | Antes | Después |
|---------|-------|---------|
| Active Controllers | 1 | |
| Under Replicated Partitions | 0 | |
| Bytes In/Out broker 2 | ~13 KB/s | |
| Targets UP en Prometheus | 4 | |

### Recuperación

| Métrica | Valor |
|---------|-------|
| Tiempo hasta broker-2 vuelve UP | |
| Tiempo hasta URP = 0 | |

---

## Parte 4: Tour Confluent Cloud

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El tour es práctico o demostrativo? | |
| ¿Cuánto crédito gratis ofrece CC? | |
| Tipos de cluster (Basic, Standard, Dedicated, Enterprise) | |
| ¿Por qué NO hacemos el ejercicio práctico todos? | |
| ¿Cuál es la latencia típica vs Local? | |
| Dos ventajas de Cloud sobre Local | |
| Dos desventajas de Cloud vs Local | |

---

## Parte 5: Comparativa final

| Pregunta | Tu respuesta |
|----------|-------------|
| Para una startup: ¿qué herramienta? | |
| Para empresa de 500 personas: ¿qué herramienta? | |
| Para producción crítica con compliance: ¿qué herramienta? | |
| ¿Es razonable usar varias en paralelo? | |
| ¿Por qué la elección NO es técnica? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre las opciones de monitoreo Kafka:

```



```

---

*Lab 11 - Curso de Administración de Apache Kafka con Confluent Platform*
