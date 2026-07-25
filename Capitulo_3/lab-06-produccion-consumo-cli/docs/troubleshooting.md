# Troubleshooting - Lab 06

## Problemas comunes y soluciones

---

### 1. El tópico `novatech.fleet.events` no existe

**Síntoma**: Al producir o consumir aparece `UnknownTopicOrPartitionException`.

**Causa**: El tópico no se creó al iniciar el lab.

**Solución**:
```bash
bash infra/scripts/init-events-topic.sh
```

---

### 2. Reset de offsets falla

**Síntoma**: 
```
Error: Assignments can only be reset if the group <X> is inactive,
but the current state is Stable.
```

**Causa**: Hay consumidores activos en el grupo.

**Solución**: Cerrar TODAS las terminales que tengan `consume-as-group.sh --group <X>` corriendo (Ctrl+C). Esperar 10 segundos. Reintentar el reset.

---

### 3. Consumer en grupo no recibe mensajes

**Síntoma**: Lanzas `consume-as-group.sh --group X` y no aparece nada, ni siquiera mensajes nuevos.

**Causas posibles**:
- El consumer fue asignado a particiones que no están recibiendo mensajes (raro)
- El grupo tiene offsets ya avanzados al final del log
- Hay otros consumidores en el grupo absorbiendo todo

**Solución**:
```bash
# Verificar estado del grupo
kafka-cli/describe-group.sh <NOMBRE_GRUPO>

# Si LAG es 0 en todas las particiones, no hay mensajes pendientes.
# Producir uno nuevo:
kafka-cli/produce-event.sh "test"
```

---

### 4. Rebalanceo lento

**Síntoma**: Tras matar un consumer, el rebalanceo tarda mucho (>30s).

**Causa**: Por defecto Kafka 4.x usa el protocolo cooperativo, que puede tener pausas más largas en clusters chicos.

**Solución**: paciencia (es normal en lab local). En producción se ajusta `session.timeout.ms` y `heartbeat.interval.ms`.

---

### 5. Kafbat UI no muestra los nuevos consumer groups

**Síntoma**: Lanzas un consumer en grupo `alertas` pero no aparece en Kafbat UI > Consumers.

**Solución**:
- Refrescar la pestaña del navegador (F5)
- Esperar 10 segundos (Kafbat UI refresca su cache periódicamente)
- Verificar por CLI: `kafka-cli/list-groups.sh`

---

### 6. Conflicto con otro clúster Kafka

**Síntoma**: Al ejecutar `bin/start-lab.sh` aparece `port is already allocated`.

**Causa**: Otro clúster Kafka todavía está corriendo en los mismos puertos.

**Solución**:
```bash
# Detener el otro clúster: ve a la carpeta del lab que tengas levantado
# y ejecuta su bin/stop-lab.sh
bin/stop-lab.sh

# Volver y reiniciar el Lab 06
cd ../lab-06-produccion-consumo-cli
bin/start-lab.sh
```

---

### 7. Cambiar el puerto de Kafbat UI

Si el puerto 8090 está ocupado por otro proceso, libéralo o cambia `KAFBAT_UI_PORT` en `infra/.env`.

---

*Troubleshooting - Lab 06*
