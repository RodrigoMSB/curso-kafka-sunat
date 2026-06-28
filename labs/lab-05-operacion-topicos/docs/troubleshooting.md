# Troubleshooting - Lab 04

## Problemas comunes

### 1. Conflicto de puertos al iniciar

Mismo problema que Labs anteriores. Detener Labs 01/02/03 antes de levantar este.

### 2. `Topic already exists`

Causa: tópico ya creado en intento anterior.

Solución:
```bash
kafka-cli/delete-topic.sh <NOMBRE>
# O usar --if-not-exists al crear
kafka-cli/create-topic.sh <NOMBRE> --if-not-exists ...
```

### 3. Compactación no aparenta funcionar

Es esperado: la compactación es asíncrona. En producción puede tardar minutos. Para forzarla en clase, configurar:
```bash
kafka-cli/alter-topic-config.sh <TOPIC> --add segment.ms=10000 --add min.cleanable.dirty.ratio=0.01
```
Esto fuerza segments cortos y umbral bajo, acelerando la compactación.

### 4. `perf-test` muy lento (<1000 msg/seg)

Causas posibles:
- Docker Desktop con poca RAM (subir a 8 GB)
- Otro proceso consumiendo CPU
- `acks=all` con red sobrecargada

### 5. `Reassignment of partition X failed`

Causa: brokers especificados en el JSON no existen o no están vivos.

Solución: verificar IDs de brokers vivos:
```bash
docker exec kafka-broker-1 kafka-broker-api-versions --bootstrap-server kafka-broker-1:29092
```

### 6. Cambiar puerto Kafbat UI

Ver troubleshooting del Lab 01.

---

*Troubleshooting - Lab 04*
