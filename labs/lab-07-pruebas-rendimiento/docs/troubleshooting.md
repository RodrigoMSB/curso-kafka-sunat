# Troubleshooting - Lab 07 (SUNAT)

## Problemas comunes

### 1. Conflicto de puertos al iniciar

Mismo problema de puertos: detener cualquier otro clúster Kafka antes de levantar este.

### 2. Throughput muy bajo (<5000 msg/seg)

**Causas**:
- Docker Desktop con poca RAM.
- Otro lab corriendo en paralelo.
- `acks=all` con red sobrecargada.

**Solución**: subir RAM de Docker a 8GB; cerrar otros labs.

### 3. Cambiar puerto Kafbat UI

Libera el puerto 8090 o cambia `KAFBAT_UI_PORT` en `infra/.env`.

---

*Troubleshooting - Lab 07 (SUNAT)*
