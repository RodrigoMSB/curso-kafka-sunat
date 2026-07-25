# Troubleshooting - Lab 11

## Síntoma 1: Schema Registry no responde

**Síntoma**: `curl http://localhost:8081/subjects` da timeout o connection refused.

**Causa**: SR depende de los brokers Kafka. Si los brokers no están healthy, SR no arranca.

**Diagnóstico**:
```bash
docker ps --filter "name=schema-registry"
docker logs schema-registry 2>&1 | tail -30
```

**Solución**:
- Verificar que los 3 brokers están UP (`docker ps`)
- Si SR muestra "Waiting for Kafka...", esperar más (puede tardar 30-60s)

---

## Síntoma 2: `kafka-avro-console-producer` falla con "Subject not found"

**Causa**: la primera vez, SR crea el subject automáticamente cuando recibe el primer mensaje. El error transitorio inicial es normal.

**Solución**: reintentar. Si persiste:
```bash
# Verificar URL de SR
docker exec schema-registry curl -s http://schema-registry:8081/subjects
```

---

## Síntoma 3: Schema v3 se registra (no debería)

**Causa**: el compatibility level del subject está en NONE en vez de BACKWARD.

**Diagnóstico**:
```bash
curl -s http://localhost:8081/config/novatech.lab10.pedidos-value
```

**Solución**: configurar BACKWARD:
```bash
curl -s -X PUT \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "BACKWARD"}' \
  http://localhost:8081/config/novatech.lab10.pedidos-value
```

---

## Síntoma 4: Conflicto de puertos con otro clúster

Detener TODOS los demás labs antes:
```bash
# desde Capitulo_N/<otro-lab>/
bin/stop-lab.sh
```

---

## Síntoma 5: Cambiar puerto Kafbat UI

Si el puerto 8090 está ocupado por otro proceso, libéralo o cambia `KAFBAT_UI_PORT` en `infra/.env`.

---

*Troubleshooting - Lab 11*
