# Reporte del Lab 06: Producción y consumo desde CLI

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: El log inmutable

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos mensajes leíste la primera vez? | |
| ¿Aparecieron de nuevo cuando re-ejecutaste consume con `--from-beginning`? | |
| Sin `--from-beginning`, ¿qué mensajes ves? | |
| ¿Por qué Kafka se comporta así? | |

### Offsets observados en Kafbat UI

| Mensaje | Offset | Partición |
|---------|--------|-----------|
| | | |
| | | |
| | | |

---

## Parte 2: Pub/Sub con múltiples consumidores

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas terminales recibieron el mensaje al producir 1? | |
| ¿En qué orden llegaron a las 3 terminales? | |
| Si esto fuera RabbitMQ, ¿cuántas habrían recibido el mensaje? | |
| ¿Apareció algún grupo en `list-groups.sh`? ¿Por qué? | |

---

## Parte 3: Offsets y replay

### Estado del grupo `alertas` antes del reset

| Partición | CURRENT-OFFSET | LOG-END-OFFSET | LAG |
|-----------|----------------|----------------|-----|
| 0 | | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El grupo `reportes` empezó desde el inicio o desde el final? | |
| Después del reset, ¿qué CURRENT-OFFSET tienen las particiones? | |
| ¿El reset de `reportes` afectó al grupo `alertas`? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre el modelo pub/sub de Kafka:

```


```

---

*Lab 02 - Curso de Administración de Apache Kafka con Confluent Platform*
