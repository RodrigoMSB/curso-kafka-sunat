# Troubleshooting - Lab 02: secciones movidas (single-broker / format / cliente externo)

> Aplican a otros labs; referencia.

### 2. Broker no arranca: "No cluster ID found"

**Síntoma**: El broker se reinicia constantemente. En logs:
```
ERROR No cluster ID found
```

**Causa**: el storage no está formateado y la auto-creación falló.

**Solución**:
```bash
docker exec <NOMBRE_CONTAINER> kafka-storage format \
    --cluster-id <TU_CLUSTER_ID> \
    --config /etc/kafka/kafka.properties \
    --ignore-formatted

docker compose restart
```

---

### 4. CLUSTER_ID inválido

**Síntoma**: error tipo `Invalid base64 cluster id`.

**Causa**: copiaste el CLUSTER_ID con espacios, saltos de línea o comillas raras.

**Solución**: regenera con `kafka-cli/generate-cluster-id.sh` y copia con cuidado (sin saltos de línea ni espacios).

---

### 5. "kafka-storage" not found

**Síntoma**: `kafka-storage: command not found`.

**Causa**: estás ejecutando el comando fuera del contenedor.

**Solución**: TODOS los `kafka-*` se ejecutan DENTRO del contenedor. Usar:
```bash
docker exec <CONTAINER_NAME> kafka-storage <args>
```

---

### 6. El cliente desde el host no se conecta

**Síntoma**: `kafka-console-producer` desde tu Mac falla con timeout.

**Causa**: `KAFKA_ADVERTISED_LISTENERS` mal configurado para EXTERNAL.

**Solución**: el listener EXTERNAL debe anunciarse como `localhost:<puerto_host>`:
```yaml
KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka-broker-1:29092,EXTERNAL://localhost:9092'
```

---

