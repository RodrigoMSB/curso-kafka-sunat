# Lab 10 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Schema Registry

### Respuestas esperadas

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Subjects al inicio | `[]` |
| ID schema v1 | Un entero, típicamente 1 |
| Versión tras v1 | 1 |
| ¿v2 compatible? | Sí (`{"is_compatible": true}`) |
| Versión tras v2 | 2 |
| ¿v3 compatible? | NO (`{"is_compatible": false}`) |
| Por qué v3 NO | Agrega campo OBLIGATORIO sin default. Un consumer leyendo datos producidos con v1 no encontraría `tarjeta_credito` y no sabe qué default usar. Rompe BACKWARD compatibility |
| Código HTTP error | 409 Conflict (Incompatible schema) |

### Reflexión

- **Sin SR**: cada equipo coordina manualmente; cualquier cambio en formato requiere comunicarse con TODOS los consumers. SR centraliza el contrato.
- **Cuándo FORWARD**: cuando consumers viejos NO se pueden actualizar (mainframes legacy, apps de terceros). Permite agregar campos siempre que tengan default razonable.
- **`_schemas` tópico**: SR usa Kafka como su backing store. Mismas garantías de durabilidad y replicación que los datos.

---

## Parte 2: Avro

### Respuestas esperadas

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Pedido Avro publicado | Sí |
| Aparece en consume-avro como JSON | Sí (kafka-avro-console-consumer deserializa) |
| 5 mensajes en Kafbat UI | Sí |
| Kafbat los muestra como JSON | Sí (integración con SR) |
| Throughput flood 50 | Variable, ~5-30 msg/seg en local |
| 4 clientes publicados | Sí |

### Reflexión

- **Avro vs JSON**: Avro ~30-50% del tamaño de JSON equivalente. La razón: schema separado, no se repiten nombres de campos en cada mensaje.
- **Por qué a gran escala**: menos bytes en red + disco + memoria. A 1M msg/seg, la diferencia es enorme.
- **Monto como string**: el producer Avro lo rechaza ANTES de publicar, validando contra el schema. Sin SR, llegaría al tópico y rompería consumers downstream.

---

## Parte 3: ksqlDB

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

## Parte 4: Desafío

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

*Solución - Lab 10*
