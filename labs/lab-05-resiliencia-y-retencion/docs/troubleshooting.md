# Troubleshooting - Lab 05

## Problemas comunes

### 1. Los tópicos del Lab 05 no se crean

Solución:
```bash
bash infra/scripts/init-lab05-topics.sh
```

### 2. `produce-continuous.sh` se queda colgado tras tumbar broker

Si `acks=all` y MIR=N pero hay menos de N brokers en ISR, el productor BLOQUEA esperando. Es comportamiento esperado. Cancelar con Ctrl+C.

### 3. La compactación "no funciona"

Es asíncrona. Para forzarla:
- Esperar 1-2 minutos
- Producir más mensajes para subir el `dirty ratio`
- Verificar configs con `kafka-cli/describe-topic.sh novatech.lab05.estado`

### 4. Watch-isr.sh no muestra cambios

- Verificar que el tópico existe: `kafka-cli/list-topics.sh`
- Verificar que hay un broker vivo
- Reducir intervalo a 1 segundo

### 5. Conflicto de puertos

Mismo problema que labs anteriores. Detener Labs 01-04 primero.

### 6. Cambiar puerto Kafbat UI

Ver troubleshooting del Lab 01.

---

*Troubleshooting - Lab 05*
