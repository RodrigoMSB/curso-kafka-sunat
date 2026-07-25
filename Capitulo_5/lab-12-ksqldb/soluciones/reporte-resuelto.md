# Lab 12 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: ksqlDB

### STREAM y TABLE

- `SHOW STREAMS` muestra `PEDIDOS_STREAM` (UPPERCASE).
- `EMIT CHANGES`: aparecen pedidos en tiempo real, latencia ~1-3s.
- `WHERE monto > 50000`: solo aparece el pedido cumpliendo el filtro (75000), no el de 5000.
- TABLE necesita PRIMARY KEY porque materializa estado: sin key no sabe qué fila reemplazar.
- Con 2 mensajes mismo key, la TABLE muestra solo el ÚLTIMO.

### Reflexión

- **STREAM vs TABLE**: STREAM = eventos (logs, transacciones); TABLE = estado actual (perfiles, configs).
- **EMIT CHANGES**: push query continuo. Sin él, ksqlDB devuelve un snapshot puntual (pull query, 0.x+).

---

## Parte 2: Desafío

### Reto 1: Filtro persistent

- Crea `PEDIDOS_ALTO_VALOR` que es un STREAM derivado.
- `SHOW QUERIES` muestra la persistent query con un ID tipo `CSAS_PEDIDOS_ALTO_VALOR_0`.
- De los 2 pedidos: solo aparece el de 99999 (cumple `monto > 50000`); el de 1000 NO.

### Reto 2: Agregación con ventana

- Aparecen filas `cliente_id, count, sum` por ventana de 1 minuto.
- Al cambiar de minuto: aparecen NUEVAS filas (la ventana anterior se "cierra").
- Es agregación POR ventana, no acumulativa eterna.

### Reto 3: JOIN stream-table

- Pedido 200 (cliente 1001 existente): `cliente_nombre = "Acme S.A. - actualizado"`, `cliente_tipo = VIP`, etc.
- Pedido 201 (cliente 9999 inexistente): `cliente_nombre = NULL`, etc. Con LEFT JOIN aparece igual; con INNER JOIN no.

### Reto 4: Filtrar VIPs

- Aparece pedido 300 (cliente 1001 = VIP).
- NO aparece pedido 301 (cliente 1002 = ESTANDAR).

### Reflexión final

- **Líneas de Java ahorradas**: cada query persistent equivale a ~200-500 líneas Kafka Streams. 4 queries = 1000-2000 líneas no escritas.
- **Reiniciar ksqlDB**: NO se pierde nada. Los streams/tables son metadatos en `_confluent-ksql-novatech_command_topic`. ksqlDB los redescubre y reinicia las queries.
- **Cuándo NO usar ksqlDB**: lógica imperativa compleja (loops, condiciones complicadas), llamadas HTTP a APIs externas, custom serializers/deserializers, algoritmos de ML. En esos casos, Kafka Streams (Java) o aplicaciones custom.
- **Bajo el capó**: cada persistent query es una aplicación Kafka Streams compilada al vuelo. Tiene sus propios offsets, state stores, etc.

---

*Solución - Lab 12*
