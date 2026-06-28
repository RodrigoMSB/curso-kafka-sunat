# Reporte del Lab 07: Consumer groups bajo presión

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Estrategias de asignación

### Range

| Consumer | Particiones |
|----------|-------------|
| 1 | |
| 2 | |
| 3 | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Distribución equitativa? | |

### RoundRobin

| Consumer | Particiones |
|----------|-------------|
| 1 | |
| 2 | |
| 3 | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Diferencia con Range? | |

### Sticky

| Pregunta | Tu respuesta |
|----------|-------------|
| Antes (3 consumers): particiones por consumer | |
| Después (4 consumers): particiones por consumer | |
| Particiones que cambiaron de dueño | |
| ¿Por qué importa minimizar re-asignación? | |

### CooperativeSticky

| Pregunta | Tu respuesta |
|----------|-------------|
| Distribución similar a Sticky | |
| Diferencia clave | |

---

## Parte 2: Lag y diagnóstico

| Pregunta | Tu respuesta |
|----------|-------------|
| LAG inicial (2 consumers, sin carga) | |
| ¿Subió el lag con flood de 50K? | |
| ¿Bajó el lag con 6 consumers? Tiempo aprox | |
| Con 14 consumers y 12 particiones: ¿cuántos ociosos? | |

---

## Parte 3: Rebalanceo

| Estrategia | Tiempo rebalanceo | Stop-the-world |
|-----------|-------------------|----------------|
| Eager (Range) | | |
| CooperativeSticky | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál recomiendas para producción? | |
| ¿Por qué? | |

---

## Parte 4: Manejo manual de offsets

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió CURRENT-OFFSET tras reset por timestamp? | |
| ¿Por qué Kafka requiere consumers inactivos para resetear? | |
| ¿Solo cambió la partición 5 con reset-to-offset? | |
| ¿Subió +1 el offset con skip-poison-message? | |
| Problema de saltar sin DLQ | |

---

## Parte 5: Desafío - Dead Letter Queue

| Pregunta | Tu respuesta |
|----------|-------------|
| Cantidad de [OK] | |
| Cantidad de [DLQ] | |
| Mensajes en DLQ | |
| Información perdida en DLQ | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué DLQ mejor que skip? | |
| ¿Qué pasa si DLQ procesador falla? | |
| ¿Cómo evitar loop infinito? | |
| Retención recomendada para DLQ | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre consumer groups en producción:

```


```

---

*Lab 07 - Curso de Administración de Apache Kafka con Confluent Platform*
