# Troubleshooting - Lab 08 (SUNAT)

## Problemas comunes

### 1. Conflicto de puertos al iniciar

**Causa**: otro clúster Kafka está corriendo en los mismos puertos.
**Solución**: detener cualquier otro clúster antes de levantar este (su `bin/stop-lab.sh`).

### 2. `add-broker.sh` no reporta healthy

**Causa**: el broker 4 tarda en unirse al quórum o falló al formatear el storage.
**Solución**: revisar `docker logs kafka-broker-4`. Verificar que `CLUSTER_ID` en `.env` sea el mismo con el que se formatearon los otros brokers. Si quedó un volumen viejo, `bin/reset-lab.sh` y volver a empezar.

### 3. La reasignación se queda "in progress"

**Causa**: hay mucho dato que copiar, o un broker va lento.
**Solución**: re-ejecutar `--verify` (el script lo hace); esperar. Subir `num.replica.fetchers` en caliente acelera la copia.

### 4. `process.roles` no se deja cambiar

**Esperado**: es read-only. No es un error del lab; es el comportamiento correcto (ver guía 02, Actividad 3).

### 5. Cambiar puerto de Kafbat UI

Si el 8090 está ocupado, cambia `KAFBAT_UI_PORT` en `infra/.env`.

---

*Troubleshooting - Lab 08 (SUNAT)*
