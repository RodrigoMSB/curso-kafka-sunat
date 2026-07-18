# Troubleshooting - Lab 01: secciones movidas (multi-broker / cliente externo)

> Aplican a labs posteriores (02 quórum, 04 listeners); se conservan aquí como referencia.

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

### 6. El cliente desde el host no se conecta

**Síntoma**: `kafka-console-producer` desde tu Mac falla con timeout.

**Causa**: `KAFKA_ADVERTISED_LISTENERS` mal configurado para EXTERNAL.

**Solución**: el listener EXTERNAL debe anunciarse como `localhost:<puerto_host>`:
```yaml
KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka-broker-1:29092,EXTERNAL://localhost:9092'
```

---

