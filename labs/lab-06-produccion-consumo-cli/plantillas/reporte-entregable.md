# Reporte del Lab 02: Pub/Sub y Consumer Groups

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

## Parte 3: Consumer Groups y escalado horizontal

### Distribución de particiones

| Cantidad de consumidores | Particiones por consumidor | Total particiones repartidas |
|--------------------------|----------------------------|------------------------------|
| 1 | | |
| 2 | | |
| 3 | | |
| 5 | | |

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Algún mensaje fue recibido por más de un consumidor del mismo grupo? | |
| Con 5 consumidores y 6 particiones, ¿hay alguno ocioso? | |
| ¿Qué pasaría con 7 consumidores? | |
| Al cerrar bruscamente uno, ¿se redistribuyeron sus particiones? | |

---

## Parte 4: Offsets y replay

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

## Parte 5: Desafío - Claves y particionado

### Predicción vs realidad

| Vehículo | Partición predicha | Partición real (Kafbat UI) |
|----------|-------------------|---------------------------|
| NVT-1001 | | |
| NVT-1002 | | |
| NVT-1003 | | |
| NVT-1004 | | |
| NVT-1005 | | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los 4 eventos de NVT-1001 cayeron en la misma partición? | |
| Con 100 vehículos y 6 particiones, ¿cuántos vehículos comparten partición en promedio? | |
| ¿Eso rompe el orden por vehículo? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre el modelo pub/sub de Kafka:

```


```

---

*Lab 02 - Curso de Administración de Apache Kafka con Confluent Platform*
