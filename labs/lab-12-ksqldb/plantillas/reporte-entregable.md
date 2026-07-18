# Reporte del Lab 12: ksqlDB

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: ksqlDB fundamentos

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

## Parte 2: Desafío - Streaming SQL completo

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

*Lab 12 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
