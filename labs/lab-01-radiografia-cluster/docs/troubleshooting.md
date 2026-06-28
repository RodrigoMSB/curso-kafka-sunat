# Troubleshooting - Lab 01

## Problemas comunes y soluciones

---

### 1. Docker sin suficiente memoria

**Síntoma**: Los brokers se reinician constantemente o no levantan. En los logs aparece `OutOfMemoryError` o el contenedor se detiene con exit code 137.

**Causa**: Docker no tiene suficiente RAM asignada. Este lab necesita al menos 6 GB para 3 brokers + Kafbat UI.

**Solución**:
```bash
# Verificar memoria asignada a Docker
docker info --format '{{.MemTotal}}'

# En Docker Desktop:
# Preferences > Resources > Memory > Mínimo 6 GB (recomendado 8 GB)
```

Después de cambiar la memoria, reiniciar Docker Desktop y ejecutar:
```bash
bin/reset-lab.sh
bin/start-lab.sh
```

---

### 2. Puertos ocupados

**Síntoma**: Error al levantar contenedores: `port is already allocated` o `address already in use`.

**Causa**: Los puertos 9092, 9093, 9094 o 8090 están siendo usados por otro proceso.

**Solución**:
```bash
# Identificar qué proceso usa el puerto (ejemplo: 9092)
lsof -i :9092

# En macOS:
sudo lsof -i -P -n | grep 9092

# Opciones:
# 1. Detener el proceso que ocupa el puerto
# 2. Modificar los puertos en infra/.env
```

Si tienes una instalación local de Kafka o un lab anterior corriendo:
```bash
# Detener cualquier contenedor Docker previo
docker stop $(docker ps -q) 2>/dev/null
```

#### Cambiar el puerto de Kafbat UI

Si solo el puerto 8090 está ocupado (no los de los brokers), puedes cambiar el puerto del Kafbat UI sin afectar el resto del laboratorio:

1. Editar `infra/.env` y modificar la línea:
   ```dotenv
   KAFBAT_UI_PORT=8090
   ```
   por cualquier puerto libre, por ejemplo:
   ```dotenv
   KAFBAT_UI_PORT=18080
   ```

2. Reiniciar el laboratorio:
   ```bash
   bin/stop-lab.sh
   bin/start-lab.sh
   ```

3. Acceder a Kafbat UI en `http://localhost:<NUEVO_PUERTO>`

**Nota técnica**: Solo cambia el puerto **del host**. Internamente el contenedor sigue escuchando en 8080, pero Docker hace el mapeo automáticamente.

---

### 3. Brokers que no levantan

**Síntoma**: `docker ps` muestra los brokers en estado `starting` o `unhealthy` por más de 2 minutos.

**Causa**: Varias posibilidades.

**Diagnóstico**:
```bash
# Ver logs del broker problemático
docker logs kafka-broker-1 2>&1 | tail -50

# Ver el estado del healthcheck
docker inspect kafka-broker-1 --format='{{json .State.Health}}'
```

**Causas comunes y soluciones**:

| Causa | Log del error | Solución |
|-------|--------------|---------|
| CLUSTER_ID inválido | `Invalid cluster id` | Verificar que `CLUSTER_ID` en `.env` es un string base64 válido |
| Inconsistencia de datos | `Log directory has unexpected cluster id` | Ejecutar `bin/reset-lab.sh` para limpiar volúmenes |
| Conflicto de node.id | `Node ID has already been used` | Ejecutar `bin/reset-lab.sh` |
| Red no disponible | `Could not resolve hostname` | Verificar que la red `novatech-network` existe: `docker network ls` |

**Solución general** (reinicio limpio):
```bash
bin/reset-lab.sh
bin/start-lab.sh
```

---

### 4. Kafbat UI no conecta

**Síntoma**: Al abrir http://localhost:8090 aparece "página no encontrada" o tarda en cargar.

**Causa**: Kafbat UI tarda ~20-30 segundos en iniciar tras los brokers. Si pasa más tiempo, puede ser un problema de pull de la imagen o de conexión a los brokers.

**Solución**:
```bash
# Verificar que el contenedor está corriendo
docker ps --filter "name=kafbat-ui"

# Ver logs de Kafbat UI
docker logs kafbat-ui 2>&1 | tail -30

# Verificar el endpoint de salud
curl -s http://localhost:8090/actuator/health
```

Si el contenedor está corriendo pero no responde:
- Esperar 30 segundos más
- Verificar que no hay un firewall bloqueando el puerto 8090
- Intentar con un navegador diferente o en modo incógnito

Si el contenedor no está corriendo:
```bash
# Reiniciar solo Kafbat UI
docker compose -f infra/docker-compose.yml restart kafbat-ui
```

---

### 5. Mensajes que no llegan al consumidor

**Síntoma**: Al ejecutar `consume-gps.sh`, no aparecen mensajes.

**Causa**: Varias posibilidades.

**Diagnóstico**:
```bash
# Verificar que el productor está generando mensajes
docker logs -f gps-producer

# Verificar que el tópico tiene datos
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.fleet.gps

# Verificar offsets del grupo consumidor
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group lab01-explorer
```

**Soluciones**:

| Causa | Solución |
|-------|---------|
| El tópico no fue creado | Ejecutar `docker exec kafka-broker-1 bash /scripts/init-topics.sh` manualmente |
| El productor no está corriendo | `docker compose -f infra/docker-compose.yml restart gps-producer` |
| El consumidor ya leyó todos los mensajes | Usar `--history` para leer desde el inicio o esperar nuevos mensajes |
| El grupo tiene offsets avanzados | Resetear offsets: `docker exec kafka-broker-1 kafka-consumer-groups --bootstrap-server kafka-broker-1:29092 --group lab01-explorer --topic novatech.fleet.gps --reset-offsets --to-earliest --execute` |

---

### 6. Permisos en scripts .sh

**Síntoma**: `Permission denied` al ejecutar cualquier script del laboratorio.

**Solución**:
```bash
# Dar permisos de ejecución a todos los scripts
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh
```

---

### 7. Error "command not found: docker compose"

**Síntoma**: El sistema no reconoce `docker compose` (sin guion).

**Causa**: Tienes Docker Compose v1 (comando `docker-compose`) en lugar de v2.

**Solución**:
- Actualizar Docker Desktop a la última versión (incluye Compose v2)
- O crear un alias temporal: `alias "docker compose"="docker-compose"`

Verificar versión:
```bash
docker compose version
# Debe mostrar: Docker Compose version v2.x.x
```

---

### 8. Rendimiento lento (macOS con Apple Silicon)

**Síntoma**: Los brokers tardan mucho en levantar o el sistema está lento.

**Causa**: Las imágenes de Confluent son `linux/amd64` y se ejecutan con emulación Rosetta en Apple Silicon.

**Solución**:
- Asegurar que Docker Desktop tiene habilitado "Use Rosetta for x86/amd64 emulation on Apple Silicon"
- Asignar al menos 8 GB de RAM a Docker
- Cerrar aplicaciones pesadas durante el laboratorio

---

### 9. El productor GPS genera datos pero el tópico no existe

**Síntoma**: El productor muestra errores de `UNKNOWN_TOPIC_OR_PARTITION`.

**Causa**: `auto.create.topics.enable` está configurado como `false` y el script `init-topics.sh` no se ejecutó correctamente.

**Solución**:
```bash
# Crear el tópico manualmente
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --create \
    --topic novatech.fleet.gps \
    --partitions 6 \
    --replication-factor 3

# Reiniciar el productor
docker compose -f infra/docker-compose.yml restart gps-producer
```

---

### 10. Contacto de soporte

Si ninguna de estas soluciones funciona:

1. Capturar la salida completa de:
   ```bash
   docker compose -f infra/docker-compose.yml logs > lab01-logs.txt 2>&1
   docker ps -a >> lab01-logs.txt
   docker info >> lab01-logs.txt
   ```
2. Compartir el archivo `lab01-logs.txt` con el instructor

---

*Troubleshooting - Lab 01*
