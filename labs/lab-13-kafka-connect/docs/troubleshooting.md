# Troubleshooting - Lab 09

## Síntoma 1: Connect tarda mucho en arrancar (>2 minutos)

**Causa**: la primera vez instala el plugin JDBC y descarga el driver PostgreSQL desde internet.

**Diagnóstico**:
```bash
docker logs kafka-connect 2>&1 | head -40
```

Deberías ver mensajes como:
- "Instalando connector JDBC..."
- "Descargando driver PostgreSQL..."
- "Iniciando Kafka Connect..."

**Solución**: esperar 90-120s la primera vez. Subsecuentes arranques son más rápidos (~30s).

---

## Síntoma 2: Source connector falla con "table not found"

**Causa**: el script `init-novatech.sql` no se ejecutó (raro pero posible si Docker reusa volumen viejo).

**Diagnóstico**:
```bash
docker exec postgres psql -U novatech -d novatech_orders -c "\dt"
```

Si NO aparece `pedidos`, el init.sql no corrió.

**Solución**:
```bash
bin/reset-lab.sh   # borra volúmenes
bin/start-lab.sh   # vuelve a aplicar init.sql
```

---

## Síntoma 3: Sink connector falla con "field 'id' missing"

**Causa**: publicaste un mensaje JSON sin el campo `id` que el Sink necesita como PK.

**Diagnóstico**:
```bash
connect-cli/status-connector.sh novatech-sink-procesados
```

Verás `state: FAILED` y un `trace` con el error.

**Solución**:
```bash
# Reiniciar el connector
curl -X POST http://localhost:8083/connectors/novatech-sink-procesados/restart

# Y publicar mensajes con campo 'id'
kafka-cli/publicar-procesado.sh 42
```

---

## Síntoma 4: El tópico `novatech.lab09.pedidos` no se crea

**Causa**: el broker tiene `auto.create.topics.enable: false` (este lab lo tiene en true, pero verificar).

**Diagnóstico**:
```bash
docker inspect kafka-broker-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep AUTO_CREATE
```

Debe mostrar `KAFKA_AUTO_CREATE_TOPICS_ENABLE=true`.

**Solución**: si está en false, modificar `docker-compose.yml` y reiniciar.

---

## Síntoma 5: Plugin JDBC no se instala (logs muestran error de red)

**Causa**: el contenedor `kafka-connect` no tiene acceso a internet o `confluent-hub` no responde.

**Diagnóstico**:
```bash
docker logs kafka-connect 2>&1 | head -30
```

Buscar mensajes como "Connection refused", "DNS resolution failed".

**Solución**: verificar conectividad de red:
```bash
docker exec kafka-connect curl -sI https://confluent.io
```

Si falla, revisar configuración de Docker Desktop > Settings > Resources > Network.

---

## Síntoma 6: Conflicto de puertos (5432, 8083, etc.)

**Causa**: tienes PostgreSQL local corriendo o un Lab anterior ocupando puertos.

**Diagnóstico**:
```bash
docker ps | grep -E '5432|8083|9092|9093|9094|8090'
lsof -i :5432
lsof -i :8083
```

**Solución**: detener procesos conflictivos. Si es un PostgreSQL del sistema, parar el servicio o cambiar el puerto en `docker-compose.yml`.

---

## Síntoma 7: REST API de Connect no responde

**Causa**: el contenedor está corriendo pero Connect aún no terminó de arrancar.

**Diagnóstico**:
```bash
docker logs kafka-connect 2>&1 | tail -20
curl -v http://localhost:8083/
```

**Solución**: esperar más tiempo. Si tras 3 minutos no responde, ver logs completos: `docker logs kafka-connect`.

---

## Síntoma 8: Cambiar puerto Kafbat UI

Ver troubleshooting del Lab 01.

---

## Síntoma: la task del Sink queda en FAILED y `restart` del connector no la recupera

### Contexto

Si el Sink connector procesó un mensaje malformado (por ejemplo, JSON sin schema cuando `schemas.enable=true`), la task queda en estado `FAILED`. El connector como entidad sigue mostrando estado `RUNNING`, pero la task no procesa más mensajes.

### Diagnóstico

```bash
connect-cli/status-connector.sh novatech-sink-procesados
```

Si ves:
```json
"connector": { "state": "RUNNING" }
"tasks": [ { "state": "FAILED", ... } ]
```

Entonces el problema es a nivel de task, NO de connector.

### Solución

**`/restart` del connector NO reinicia las tasks**, solo la definición del connector. Para reiniciar una task específica:

```bash
curl -s -X POST http://localhost:8083/connectors/novatech-sink-procesados/tasks/0/restart
```

Después de 5-10 segundos, la task vuelve a `RUNNING` y reanuda el procesamiento desde el offset donde se quedó.

### Lección clave

En Kafka Connect, **connector** y **tasks** son entidades separadas:
- El **connector** es la definición (configuración).
- Las **tasks** son los workers que ejecutan el trabajo.

Un connector puede estar RUNNING mientras sus tasks están FAILED. Para resolver problemas de procesamiento, casi siempre hay que reiniciar las tasks específicas, no el connector entero.

### Síntoma relacionado: mensaje "envenenado" bloquea la task

Si un mensaje en el tópico tiene formato incompatible con la config del Sink, la task se atasca en ese mensaje. Reiniciar la task NO ayuda porque el offset sigue apuntando al mismo mensaje malformado.

**Solución:** borrar el tópico y recrearlo (datos perdidos), o avanzar el offset manualmente del consumer group del Sink:

```bash
# Avanzar offset al final del tópico (ignora todos los mensajes pendientes)
docker exec kafka-broker-1 kafka-consumer-groups \
  --bootstrap-server kafka-broker-1:29092 \
  --group connect-novatech-sink-procesados \
  --topic novatech.lab09.pedidos.procesados \
  --reset-offsets --to-latest --execute
```

(Solo funciona con la task detenida; si está corriendo, debe pausarse antes.)

---

*Troubleshooting - Lab 09*
