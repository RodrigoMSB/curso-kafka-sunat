# Troubleshooting - Lab 08

## Síntoma 1: Control Center muestra dashboards vacíos

**Causa más común**: el ConfluentMetricsReporter no está habilitado en los brokers.

**Diagnóstico:**
```bash
# Verificar que el tópico interno existe
docker exec kafka-broker-1 kafka-topics \
  --bootstrap-server kafka-broker-1:29092 \
  --list | grep _confluent-metrics

# Verificar que tiene mensajes
docker exec kafka-broker-1 kafka-console-consumer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic _confluent-metrics \
  --from-beginning --max-messages 1 --timeout-ms 5000
```

Si el tópico NO existe o NO tiene mensajes, revisar en `docker-compose.yml`:
- `KAFKA_METRIC_REPORTERS: io.confluent.metrics.reporter.ConfluentMetricsReporter`
- `KAFKA_CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS` apunta a los brokers
- `KAFKA_CONFLUENT_METRICS_ENABLE: "true"`

## Síntoma 2: Control Center tarda mucho en arrancar

CC Legacy 7.9.0 tarda 60-120s en estar listo. Es normal.

Si después de 3 minutos no responde:
```bash
docker logs control-center 2>&1 | tail -50
```

Errores comunes:
- "Topic not found": esperar más, los tópicos internos se crean al arrancar
- "License expired": detener con `bin/stop-lab.sh` y volver a iniciar (la license se renueva)

---

## Problemas comunes

### 1. Control Center no levanta o tarda mucho

**Síntoma**: `bin/start-lab.sh` se queda en "Esperando Control Center" más de 3 minutos.

**Causas**:
- Docker tiene poca RAM (necesita 8 GB)
- Imagen aún descargando (la primera vez)
- Brokers todavía inicializando

**Solución**:
```bash
# Ver logs
docker logs control-center 2>&1 | tail -50

# Ver estado
docker ps --filter "name=control-center"
```

Si los logs muestran "Waiting for Kafka...", esperar más (puede tardar 90-120s la primera vez). Aumentar RAM Docker a 6-8 GB si tiene menos.

---

### 2. License expirada de cp-server

**Síntoma**: brokers no levantan, logs muestran error de license.

**Solución**:
```bash
bin/reset-lab.sh
bin/start-lab.sh
```

Esto borra los volúmenes (incluyendo el estado de la license) y reinicia el período de evaluación.

Para producción real: agregar `CONFLUENT_LICENSE` env var con la licencia comercial.

---

### 3. Métricas vacías en CC tras 5 minutos

**Síntoma**: el clúster está corriendo, hay carga, pero CC muestra dashboards vacíos.

**Solución**:
```bash
# Verificar que los brokers tienen el MetricsReporter activo
docker logs kafka-broker-1 2>&1 | grep -i ConfluentMetricsReporter | tail -10

# Verificar que CC está consumiendo
docker logs control-center 2>&1 | grep -i metrics | tail -10
```

Si no hay actividad, ver Síntoma 1 (revisar variables `KAFKA_METRIC_REPORTERS` y `KAFKA_CONFLUENT_METRICS_*`).

---

### 4. Conflicto de puertos con labs anteriores

**Síntoma**: `port is already allocated` al levantar.

**Solución**:
```bash
# Detener TODOS los demás labs
for lab in lab-01-radiografia-cluster lab-02-pubsub-en-accion lab-04-operando-topicos lab-05-resiliencia-y-retencion lab-06-productores-afilados lab-07-consumer-groups-bajo-presion; do
    if [ -f "../$lab/bin/stop-lab.sh" ]; then
        echo "Deteniendo $lab"
        bash "../$lab/bin/stop-lab.sh" 2>/dev/null || true
    fi
done
```

---

### 5. Docker se queda sin recursos

**Síntoma**: contenedores se reinician constantemente o quedan en "OOMKilled".

**Solución**: subir RAM de Docker Desktop:
- Mac/Windows: Docker Desktop > Settings > Resources > Memory > 6-8 GB > Apply & Restart
- Linux: ajustar `--memory` en daemon.json

---

### 6. Cambiar puerto Kafbat UI (8090 ocupado)

Ver troubleshooting del Lab 01.

---

*Troubleshooting - Lab 08*
