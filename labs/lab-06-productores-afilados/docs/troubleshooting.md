# Troubleshooting - Lab 06

## Problemas comunes

### 1. Conflicto de puertos al iniciar

Mismo problema que labs anteriores. Detener Labs 01-05 primero.

### 2. `kafka-transactions: command not found`

**Causa**: imagen demasiado vieja.

**Solución**: confirmar que estás usando `confluentinc/cp-kafka:8.2.0` (no versiones < 7.0).

```bash
docker exec kafka-broker-1 ls /usr/bin/ | grep transactions
```

Debe aparecer `kafka-transactions`.

### 3. `enable.idempotence=true` falla con `ConfigException`

**Síntoma**: `Must set acks to all in order to use the idempotent producer`.

**Causa**: estás forzando `acks=1` o `acks=0` junto con idempotencia.

**Solución**: con idempotencia debes usar `acks=all` (o no especificar acks, el default ya es correcto).

### 4. El productor naive NO muestra duplicados

**Causa**: en local sin congestión, los reintentos no se disparan.

**Soluciones**:
- Bajar `request.timeout.ms` a 50ms editando el script.
- Re-ejecutar varias veces seguidas (acumula carga en el broker).
- Usar `tc qdisc add dev lo root netem delay 100ms` para agregar latencia artificial (Linux).

### 5. `read_committed` no muestra diferencia con `read_uncommitted`

**Causa**: la implementación CLI de transacciones de este lab tiene limitaciones. El control fino requiere código de aplicación.

**Mitigación**: explicar la limitación pedagógica en clase. Lo que sí se valida: el COMANDO funciona, el concepto se entiende.

### 6. Throughput muy bajo (<5000 msg/seg)

**Causas**:
- Docker Desktop con poca RAM.
- Otro lab corriendo en paralelo.
- `acks=all` con red sobrecargada.

**Solución**: subir RAM de Docker a 8GB; cerrar otros labs.

### 7. Cambiar puerto Kafbat UI

Ver troubleshooting del Lab 01.

---

*Troubleshooting - Lab 06*
