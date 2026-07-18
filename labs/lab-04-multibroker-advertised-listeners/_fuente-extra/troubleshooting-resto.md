# Troubleshooting - Lab 04: secciones movidas (single/format/quórum)

> Referencia.

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

### 3. Los 3 brokers no se descubren entre sí

**Síntoma**: `bin/check-quorum.sh` muestra solo 1 voter, no 3.

**Causa probable**: distintos CLUSTER_ID o distintos QUORUM_VOTERS entre los brokers.

**Solución**:
```bash
# Verificar que los 3 brokers tienen el MISMO CLUSTER_ID
for i in 1 2 3; do
    echo "=== broker-$i ==="
    docker exec kafka-broker-$i cat /var/lib/kafka/data/meta.properties 2>/dev/null | grep cluster.id
done
```

Si difieren, hay que hacer reset:
```bash
bin/reset-mi-cluster.sh
```

Y volver a empezar desde la Parte 3 con un CLUSTER_ID único.

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

