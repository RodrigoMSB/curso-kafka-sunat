# Reporte del Lab 09: Kafka Connect con PostgreSQL

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Arquitectura de Kafka Connect

| Pregunta | Tu respuesta |
|----------|-------------|
| Versión de Kafka Connect | |
| `kafka_cluster_id` que muestra | |
| ¿Aparece `JdbcSourceConnector` en plugins? | |
| ¿Aparece `JdbcSinkConnector` en plugins? | |
| Tópicos `_connect-*` que viste | |
| ¿Para qué sirve cada tópico? | |
| ¿Aparece el cluster en Kafbat UI > Connect? | |

---

## Parte 2: Source connector JDBC

### Estado del connector

| Atributo | Valor |
|----------|-------|
| `connector.state` | |
| Cantidad de tasks | |
| `tasks[0].state` | |

### Captura de datos

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos pedidos seed leíste? | |
| Formato de los mensajes | |
| Campos JSON observados | |
| Tiempo entre INSERT y mensaje en Kafka | |
| ¿Por qué tardó ~5s? | |

### Inserción masiva

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecieron los 10 nuevos? | |
| ¿En orden de inserción? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasa si tumbas Connect a la mitad? | |
| ¿Por qué `mode: incrementing` solo detecta INSERT? | |
| ¿Cómo capturarías UPDATE/DELETE? | |

---

## Parte 3: Sink connector JDBC

| Pregunta | Tu respuesta |
|----------|-------------|
| Tabla destino vacía al inicio | Sí / No |
| `connector.state` después de crear | |
| Tras publicar id=1, ¿apareció en la tabla? | |
| Tras publicar OTRA vez con id=1, ¿se duplicó o actualizó? | |
| ¿Por qué? | |

### Mensaje malformado

| Pregunta | Tu respuesta |
|----------|-------------|
| Estado del connector tras malformado | |
| Error en el `trace` | |
| Cómo se recupera | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué `auto.create: false`? | |
| ¿Cuándo upsert vs insert? | |
| ¿Qué pasa si el Sink se atrasa? | |

---

## Parte 4: Desafío - Flow completo

| Pregunta | Tu respuesta |
|----------|-------------|
| Pedidos nuevos en `pedidos` | |
| IDs que viste en Kafka | |
| 5 mensajes "procesados" publicados sin error | Sí / No |
| Registros en `pedidos_procesados` | |
| Tiempo total del flujo | |

### Reflexión final

| Pregunta | Tu respuesta |
|----------|-------------|
| Líneas de código escritas | |
| ¿Qué te ahorraste vs Python? | |
| ¿Qué pasa si Connect cae a la mitad? | |
| Diferencia con Debezium | |
| Otros conectores útiles para NovaTech | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre integración con Kafka Connect:

```



```

---

*Lab 09 - Curso de Administración de Apache Kafka con Confluent Platform*
