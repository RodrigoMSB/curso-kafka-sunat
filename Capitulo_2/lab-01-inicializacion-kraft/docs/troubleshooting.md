# Troubleshooting - Lab 01 (SUNAT)

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

### 2. Broker no arranca: "No cluster ID found"

**Síntoma**: El broker se reinicia constantemente. En logs:
```
ERROR No cluster ID found
```

**Causa**: el storage no está formateado y la auto-creación falló.

**Solución**:
```bash
MSYS_NO_PATHCONV=1 docker exec <NOMBRE_CONTAINER> kafka-storage format \
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

*Troubleshooting - Lab 01 (SUNAT)*
