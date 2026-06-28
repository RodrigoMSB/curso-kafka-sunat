# Troubleshooting - Lab 07

## Problemas comunes

### 1. Conflicto de puertos al iniciar

Mismo problema que labs anteriores. Detener Labs 01-06 primero.

### 2. Tópicos del Lab 07 no existen

Solución:
```bash
bash infra/scripts/init-lab07-topics.sh
```

### 3. Reset falla por consumers activos

**Síntoma**: `Assignments can only be reset if the group <X> is inactive`

**Solución**: cerrar TODAS las terminales que tengan consumers de ese grupo. Esperar 10 segundos. Reintentar.

### 4. Monitor de lag muestra "-"

**Causa**: la partición no tuvo commits aún (consumer recién unido o nunca consumió).

**Solución**: producir mensajes y esperar a que los consumers commiten al menos una vez.

### 5. No veo rebalanceo al matar un consumer

**Causa**: cerraste graceful en vez de bruscamente.

**Solución**: usar Ctrl+C múltiple o `docker exec` para matar el proceso JVM.

### 6. `consume-with-strategy` falla con error de strategy

**Causa**: nombre de estrategia mal escrito.

**Solución**: usar exactamente `range`, `roundrobin`, `sticky`, o `cooperative`.

### 7. DLQ en consume-with-dlq.sh aparece vacía

**Causa**: el patrón no matcheó ningún mensaje.

**Solución**: verificar que el patrón coincide con el contenido real:
```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab07.eventos \
    --from-beginning --max-messages 5 --timeout-ms 5000
```

### 8. Cambiar puerto Kafbat UI

Ver troubleshooting del Lab 01.

---

*Troubleshooting - Lab 07*
