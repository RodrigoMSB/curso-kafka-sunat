# Reporte de Laboratorio 01: Radiografía de un clúster Kafka vivo

## Datos del alumno

| Campo | Valor |
|-------|-------|
| **Nombre** | |
| **Fecha** | |
| **Sección** | |

---

## Sección 1: Componentes del clúster

Lista los componentes que identificaste en el clúster NovaTech:

| Componente | Imagen Docker | Puerto externo | Rol / Función |
|-----------|--------------|----------------|---------------|
| kafka-broker-1 | | | |
| kafka-broker-2 | | | |
| kafka-broker-3 | | | |
| kafbat-ui | | | |
| gps-producer | | | |

### Controlador KRaft

| Dato | Valor |
|------|-------|
| Leader ID | |
| Votantes | |
| Epoch actual | |

---

## Sección 2: Distribución de particiones

### Tópico: `novatech.fleet.gps`

| Partición | Broker líder | Réplicas | ISR | ¿Todas sincronizadas? |
|-----------|-------------|----------|-----|----------------------|
| 0 | | | | |
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |

### Análisis de distribución

- ¿Los líderes están balanceados entre los brokers? _______
- ¿Cuántas particiones lidera cada broker?
  - Broker 1: ___
  - Broker 2: ___
  - Broker 3: ___

---

## Sección 3: Tolerancia a fallos

### Estado ANTES de la caída

| Partición | Líder | ISR |
|-----------|-------|-----|
| 0 | | |
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

Controlador activo: ___

### Estado DESPUÉS de la caída (Broker 2 detenido)

| Partición | Líder | ISR |
|-----------|-------|-----|
| 0 | | |
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

Controlador activo: ___

### Estado DESPUÉS de la recuperación

| Partición | Líder | ISR |
|-----------|-------|-----|
| 0 | | |
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

Controlador activo: ___

### Observaciones

- ¿El productor GPS siguió funcionando durante la caída? ___
- ¿Se perdieron mensajes? ___
- ¿El broker recuperado volvió a ser líder de alguna partición? ___
- Tiempo aproximado de resincronización: ___

---

## Sección 4: Conclusiones

### ¿Qué aprendí sobre la arquitectura de Kafka?

> _Escribe tu conclusión aquí..._

### ¿Qué aprendí sobre la tolerancia a fallos?

> _Escribe tu conclusión aquí..._

### ¿Qué rol juegan las réplicas ISR en la resiliencia del clúster?

> _Escribe tu conclusión aquí..._

---

## Sección 5: Desafío extra (opcional)

### Reto 1: Volumen de datos

| Dato | Valor |
|------|-------|
| Bytes totales en `novatech.fleet.gps` | |
| Comando utilizado | |

### Reto 2: Distribución de datos

| Dato | Valor |
|------|-------|
| Partición con más datos | |
| Partición con menos datos | |
| Hipótesis de la diferencia | |

### Reto 3: Kafbat UI

| Dato | Valor |
|------|-------|
| ¿Cuántos brokers muestra la sección "Brokers"? | |
| ¿Qué broker aparece marcado como controlador del KRaft? | |
| ¿Cuántas particiones muestra el tópico `novatech.fleet.gps`? | |
| Throughput aproximado (mensajes/segundo) | |
| ¿Aparece el consumer group `lab01-explorer`? | |
| Screenshot de la vista de mensajes adjunto | Sí / No |

---

## Diagrama

- [ ] Adjunto diagrama completado (draw.io o foto de papel)

---

*Laboratorio 01 - Curso de Administración de Apache Kafka con Confluent Platform*
