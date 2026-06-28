# Troubleshooting - Lab 05

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

### 4. Cambiar puerto Kafbat UI

Si el puerto 8090 está ocupado por otro proceso, libéralo o cambia `KAFBAT_UI_PORT` en `infra/.env`.

---

*Troubleshooting - Lab 05*
