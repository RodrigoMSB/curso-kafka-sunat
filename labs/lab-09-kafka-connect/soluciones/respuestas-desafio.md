# Lab 09 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1-4: Flujo end-to-end

### Comportamiento esperado

Los 5 pedidos insertados aparecen en Kafka en ~5 segundos. Los 5 mensajes "procesados" aparecen en `pedidos_procesados` en otros ~5 segundos. Tiempo total: ~10-15s.

### Tabla esperada después del flujo

```sql
SELECT id, cliente_id, producto, estado, procesado_en
FROM pedidos_procesados
ORDER BY procesado_en DESC LIMIT 10;
```

5 registros con IDs 6-10 (suponiendo que arrancaste con 5 seed + 5 desafío).

---

## Reto 5: Reflexión final

### Líneas de código escritas: CERO

Toda la lógica está en:
- `jdbc-source-pedidos.json`: 17 líneas de config JSON
- `jdbc-sink-procesados.json`: 18 líneas de config JSON

Total: 35 líneas de **configuración declarativa**, no código.

### Vs implementación con Python

Para hacer lo mismo en Python necesitarías:
1. Cliente de PostgreSQL (psycopg2)
2. Cliente de Kafka (confluent-kafka-python)
3. Lógica de polling de la tabla con tracking del último id visto
4. Persistencia del último id (en archivo o tabla)
5. Manejo de errores: timeouts, reconexión, retries
6. Logging
7. Health checks
8. Despliegue (Dockerfile, supervisord, etc.)
9. Misma cosa para el flujo Kafka → PostgreSQL

Probablemente **500-1000 líneas de código** + tests + ops.

Connect te da TODO eso "gratis" a cambio de aprender la sintaxis declarativa.

### Si Connect cae a la mitad

- Los offsets están en `_connect-offsets` (tópico replicado en 3 brokers).
- Al reiniciar Connect, lee el último offset procesado y continúa desde ahí.
- En modo distributed con múltiples workers, las tasks se redistribuyen automáticamente.
- **No pierde mensajes ni duplica** (assuming idempotencia del sink, que el JDBC Sink con upsert garantiza).

### Diferencia con Debezium

| Aspecto | JDBC connector (este lab) | Debezium |
|---------|---------------------------|----------|
| Modo de captura | Polling (cada 5s) | Streaming del WAL |
| Latencia | ~5 segundos | <100 ms |
| Captura UPDATE | NO (con incrementing) | SÍ |
| Captura DELETE | NO | SÍ |
| Carga en DB | Query SELECT cada 5s | Lee log de transacciones |
| Configuración | Más simple | Requiere replicación de PostgreSQL |
| Caso de uso | Demos, datos con alta latencia tolerable | CDC real-time, productos críticos |

**Regla**: para producción seria, usar Debezium. Para introducción pedagógica, JDBC.

### Otros conectores útiles para NovaTech

- **S3 Sink**: archivar todos los pedidos a S3 para compliance/auditoría
- **Elasticsearch Sink**: indexar pedidos para búsqueda full-text
- **MongoDB Source/Sink**: si NovaTech tiene catálogo de productos en MongoDB
- **HTTP Sink**: notificar APIs externas (ej. confirmación al cliente)
- **Salesforce Source**: si hay datos de CRM
- **Twilio/SendGrid Sink**: SMS/email cuando se procese un pedido
- **Snowflake Sink**: enviar al data warehouse para analytics

Confluent Hub tiene 200+ conectores oficiales.

---

## Reto 6: Inspección con Kafbat UI

Kafbat UI > Connect muestra:
- Lista de conectores con estado (RUNNING, FAILED, etc.)
- Configuración de cada uno
- Tasks y su distribución
- Permite reiniciar/eliminar conectores desde la UI

Útil para operación diaria sin tener que recordar comandos `curl`.

---

*Soluciones del desafío - Lab 09*
