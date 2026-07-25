# Troubleshooting - Lab 10 (SUNAT)

## Problemas comunes

### 1. Conflicto de puertos al iniciar

**Causa**: otro clúster Kafka (o algo en 8082/8090) está corriendo.
**Solución**: detener cualquier otro clúster antes de levantar este.

### 2. `curl` a :8082 no responde

**Causa**: el REST Proxy tarda en arrancar (depende de que los brokers estén healthy).
**Solución**: esperar; revisar `docker logs kafka-rest`. Verificar con `curl -s http://localhost:8082/topics`.

### 3. El POST de producción da error 415 (Unsupported Media Type)

**Causa**: falta o está mal el header `Content-Type: application/vnd.kafka.json.v2+json`.
**Solución**: incluir el header exacto en el `curl`.

### 4. El consumer no trae mensajes

**Causa**: solo hiciste un poll (el primero inicializa, suele venir vacío).
**Solución**: hacer un segundo poll. El script `rest-consume.sh` ya hace los dos.

### 5. Error al crear la instancia de consumer (409 Conflict)

**Causa**: ya existe una instancia con ese nombre en el grupo.
**Solución**: borrarla (`DELETE .../instances/<nombre>`) o usar otro nombre. `rest-consume.sh` usa un nombre único por PID.

### 6. Cambiar puerto de Kafbat UI

Si el 8090 está ocupado, cambia `KAFBAT_UI_PORT` en `infra/.env`.

---

*Troubleshooting - Lab 10 (SUNAT)*
