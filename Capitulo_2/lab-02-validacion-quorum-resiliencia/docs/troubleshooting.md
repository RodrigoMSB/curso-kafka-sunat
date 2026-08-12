# Troubleshooting - Lab 02 (SUNAT)

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

### 3. Los 3 brokers no se descubren entre sí

**Síntoma**: `bin/check-quorum.sh` muestra solo 1 voter, no 3.

**Causa probable**: distintos CLUSTER_ID o distintos QUORUM_VOTERS entre los brokers.

**Solución**:
> **Si usas Git Bash en Windows:** `MSYS_NO_PATHCONV=1` le dice a Git Bash que no toque
> las rutas de este comando. Sin él, Windows convierte `/var/lib/kafka/...` —que es una ruta
> **dentro del contenedor**— en una ruta de tu disco, y el comando falla. En Linux o macOS
> el prefijo no hace nada y no molesta.

```bash
# Verificar que los 3 brokers tienen el MISMO CLUSTER_ID
for i in 1 2 3; do
    echo "=== broker-$i ==="
    MSYS_NO_PATHCONV=1 docker exec kafka-broker-$i cat /var/lib/kafka/data/meta.properties 2>/dev/null | grep cluster.id
done
```

Si difieren, hay que hacer reset:
```bash
bin/reset-mi-cluster.sh
```

Y volver a empezar desde la Parte 3 con un CLUSTER_ID único.

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

*Troubleshooting - Lab 02 (SUNAT)*
