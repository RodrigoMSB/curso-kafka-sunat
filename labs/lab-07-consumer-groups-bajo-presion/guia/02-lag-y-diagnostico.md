# Parte 2: Lag y diagnóstico

## Objetivo

Generar lag intencionalmente y aprender a medirlo, monitorearlo y diagnosticar su causa.

## Contexto

**Lag** = mensajes pendientes de consumir = `LOG-END-OFFSET - CURRENT-OFFSET`. Lag creciente significa que los consumers no dan abasto. Es la métrica #1 que monitoreas en producción.

---

## Actividad 1: Estado base (sin lag)

Lanza **2 consumers** en grupo `alertas` (terminal A y B):

```bash
kafka-cli/consume-with-strategy.sh --group alertas --strategy cooperative
```

Verifica el lag (en una tercera terminal):
```bash
kafka-cli/describe-group.sh alertas
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué LAG tiene cada partición? (debe ser 0 o muy bajo) | |

---

## Actividad 2: Generar lag con flood

En una **cuarta terminal**, lanza el monitor:
```bash
kafka-cli/monitor-lag.sh alertas 2
```

En una **quinta terminal**, dispara el flood:
```bash
kafka-cli/produce-flood.sh 50000
```

**Observa el monitor de lag.**

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El lag total subió? | |
| ¿Qué tan rápido sube? | |
| ¿Eventualmente baja sin agregar más consumers? | |

---

## Actividad 3: Agregar consumers para reducir lag

Sin detener nada, abre 4 terminales más con el mismo grupo:
```bash
kafka-cli/consume-with-strategy.sh --group alertas --strategy cooperative
```

Ahora tienes 6 consumers (terminales A, B + 4 nuevas) procesando en paralelo.

Sigue mirando el monitor.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El lag bajó más rápido con 6 consumers? | |
| ¿Cuánto tardó en llegar a 0 (o cerca)? | |

---

## Actividad 4: ¿Y si tengo más consumers que particiones?

12 particiones, ya tienes 6 consumers. Agrega 8 más (total 14):

```bash
# 8 terminales adicionales con
kafka-cli/consume-with-strategy.sh --group alertas --strategy cooperative
```

```bash
kafka-cli/describe-group.sh alertas
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos consumers tienen 0 particiones (idle)? | |
| ¿Por qué? | |

---

## Conclusiones

| Concepto | Lo aprendiste midiendo... |
|----------|--------------------------|
| Lag | Diferencia LOG_END - CURRENT |
| Crecer/decrecer | Velocidad relativa producer vs consumers |
| Escalado | Más consumers = menos lag (hasta el límite) |
| Tope | Más consumers que particiones = ociosos |

---

## Cierre

Cierra TODAS las terminales con Ctrl+C antes de continuar.

---

## Siguiente paso

Continúa con [Parte 3: Rebalanceo en vivo](03-rebalanceo-en-vivo.md).
