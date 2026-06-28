# Reporte del Lab 05: Resiliencia y políticas de retención

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: ISR bajo el microscopio

### Estado inicial del tópico `novatech.lab05.resiliente`

| Partición | Leader | Replicas | ISR |
|-----------|--------|----------|-----|
| 0 | | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿ISR coincide con Replicas en todas? | |
| `min.insync.replicas` configurado | |
| Al tumbar broker 2, ¿productor siguió enviando? | |
| ¿ISR cambió? ¿Cómo? | |
| Particiones que cambiaron de líder | |
| Al revivir broker 2, ¿volvió al ISR? | |
| ¿Recuperó rol de líder o quedó como follower? | |

---

## Parte 2: Carrera contra `min.insync.replicas`

| Pregunta | Tu respuesta |
|----------|-------------|
| Producir al ESTRICTO con 3 brokers vivos: ¿funcionó? | |
| Tras tumbar 1 broker, ISR del estricto | |
| ¿ISR (2) menor que MIR (3)? | |
| Error al producir al estricto | |
| ¿Por qué Kafka rechaza la escritura? | |
| Al producir al RESILIENTE en mismas condiciones: ¿funcionó? | |
| ¿Por qué SÍ funcionó aquí? | |
| Al revivir broker, ¿volvió a funcionar el estricto? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué casi nadie usa MIR=3 con RF=3 en producción? | |
| Tradeoff de MIR=2 con RF=3 | |
| Configuración para sistema de pagos | |

---

## Parte 3: Recuperación y catch-up

| Pregunta | Tu respuesta |
|----------|-------------|
| Producción de 5K mensajes con broker 2 caído: tiempo | |
| Tiempo de catch-up al revivir broker 2 | |
| ¿Entró al ISR de todas las particiones simultáneamente? | |
| ¿Recuperó rol de líder? | |
| Total de mensajes en el tópico | |
| ¿Coincide con lo esperado? | |
| ¿Por qué no se perdieron mensajes? | |

---

## Parte 4: Retención por tiempo en vivo

| Métrica | Valor |
|---------|-------|
| OFFSET_INICIAL después de producir 100 mensajes | |
| Offset más antiguo después de 90 segundos | |
| ¿Hubo eliminación inmediata? | |
| Offset más antiguo tras producción periódica | |
| Offset más nuevo tras producción periódica | |
| Mensajes vivos | |
| Tamaño de `efimero` (Kafbat UI) | |
| Tamaño de `resiliente` (Kafbat UI) | |
| ¿Por qué difieren? | |

---

## Parte 5: Desafío - Compactación y tombstones

| Pregunta | Tu respuesta |
|----------|-------------|
| Mensajes producidos en estado | 30 |
| Mensajes leídos tras esperar | |
| Claves distintas observadas | |
| ¿Cada vehículo aparece más de una vez? | |
| Después del tombstone NVT-3, ¿siguió apareciendo? | |
| ¿Apareció NVT-3 -> NULL_VALUE? | |
| Después de 60s, ¿qué pasó con NVT-3? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| Casos ideales para compactación | |
| ¿Por qué requiere KEY? | |
| ¿Qué pasa con mensaje sin clave en tópico compactado? | |
| ¿Por qué tombstones tienen su propio retention? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre resiliencia y retención en Kafka:

```


```

---

*Lab 05 - Curso de Administración de Apache Kafka con Confluent Platform*
