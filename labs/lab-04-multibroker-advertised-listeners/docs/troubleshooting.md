# Troubleshooting - Lab 04 (SUNAT)

## Problemas comunes y soluciones

---

### 1. "Address already in use" al levantar mi-cluster

**Síntoma**: error sobre puertos 9092, 9093 o 9094.

**Causa**: otro clúster Kafka está corriendo en los mismos puertos.

**Solución**:
```bash
# Verificar qué está usando los puertos
docker ps | grep -E '9092|9093|9094'

# Detener el otro clúster: ve a la carpeta del lab que tengas levantado
# y ejecuta su bin/stop-lab.sh
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

### 7. ¿Cómo empezar de cero si la cago?

```bash
# Detener Y borrar volúmenes
bin/reset-mi-cluster.sh

# Editar tu docker-compose.yml para corregir lo que sea
nano mi-cluster/docker-compose.yml

# Regenerar CLUSTER_ID (porque borraste el storage)
kafka-cli/generate-cluster-id.sh

# Levantar de nuevo
cd mi-cluster && docker compose up -d
```

---

*Troubleshooting - Lab 04 (SUNAT)*
