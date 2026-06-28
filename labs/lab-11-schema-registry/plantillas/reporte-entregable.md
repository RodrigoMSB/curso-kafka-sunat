# Reporte del Lab 10: Schema Registry + ksqlDB

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Schema Registry

| Pregunta | Tu respuesta |
|----------|-------------|
| Subjects al inicio | |
| ID del schema v1 registrado | |
| Versión del subject tras v1 | |
| ¿v2 (con campo opcional) es compatible? | |
| Versión tras registrar v2 | |
| ¿v3 (campo obligatorio sin default) es compatible? | |
| Por qué v3 NO es compatible | |
| Código HTTP de error al registrar v3 | |
| Subject visible en Kafbat UI | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasaría sin Schema Registry? | |
| ¿Cuándo cambiarías a FORWARD? | |
| ¿Por qué `_schemas` es un tópico Kafka? | |

---

## Parte 2: Avro en acción

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Pedido Avro publicado sin error? | |
| ¿Apareció en consume-avro como JSON? | |
| Mensajes en Kafbat UI tras 5 producciones | |
| ¿Kafbat los muestra deserializados? | |
| Throughput tras flood de 50 | |
| ¿Los 4 clientes publicados? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| Tamaño Avro vs JSON | |
| Por qué Avro es mejor a gran escala | |
| ¿Qué pasa con `monto` como string? | |

---

## Parte 3: ksqlDB fundamentos

### STREAM

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿`SHOW STREAMS` muestra `PEDIDOS_STREAM`? | |
| ¿Aparecieron pedidos con EMIT CHANGES? | |
| Latencia entre producir y ver en ksqlDB | |
| ¿Cuál pedido apareció con WHERE > 50000? | |

### TABLE

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿`SHOW TABLES` muestra `CLIENTES_TABLE`? | |
| Por qué TABLE necesita PRIMARY KEY | |
| Tras 2 mensajes con misma key, ¿cuántas filas en la TABLE? | |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| Cuándo usar STREAM vs TABLE | |
| ¿Qué significa EMIT CHANGES? | |

---

## Parte 4: Desafío - Streaming SQL completo

### Reto 1: Filtro persistent

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece `PEDIDOS_ALTO_VALOR`? | |
| Query ID en SHOW QUERIES | |
| ¿De los 2 pedidos producidos, cuál apareció? | |

### Reto 2: Agregación con ventana

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparecen conteos por cliente_id? | |
| ¿Qué pasa al cambiar de minuto? | |

### Reto 3: JOIN stream-table

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Pedido 200 con cliente 1001 trajo datos del cliente? | |
| ¿Pedido 201 con cliente 9999 (inexistente)? | |

### Reto 4: Filtrar VIPs

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál pedido apareció (300 VIP o 301 estándar)? | |

### Reflexión final

| Pregunta | Tu respuesta |
|----------|-------------|
| Líneas de Java ahorradas | |
| ¿Qué pasa al reiniciar ksqlDB? | |
| Cuándo NO usar ksqlDB | |
| Qué hace una persistent query bajo el capó | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste sobre Schema Registry y ksqlDB:

```



```

---

*Lab 10 - Curso de Administración de Apache Kafka con Confluent Platform*
