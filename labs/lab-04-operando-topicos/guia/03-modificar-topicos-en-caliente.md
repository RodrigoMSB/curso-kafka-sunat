# Parte 3: Modificar tópicos en caliente

## Objetivo

Aprender a cambiar configuraciones de tópicos **sin reiniciar nada**, y entender qué se puede aumentar (particiones), qué se puede modificar (configs) y qué es irreversible.

## Contexto

NovaTech está en producción y de pronto el CFO pide: *"el tópico de auditoría debe pasar de 90 a 365 días por nueva regulación"*. El equipo de operaciones GPS dice: *"la flota creció, necesitamos más paralelismo, súbele las particiones a `novatech.gps.realtime`"*.

Tu trabajo: aplicar estos cambios sin downtime.

---

## Actividad 1: Cambiar retención (caso CFO)

Verifica el valor actual:

```bash
kafka-cli/describe-topic.sh novatech.audit.events | grep retention.ms
```

Aplica el cambio:

```bash
kafka-cli/alter-topic-config.sh novatech.audit.events \
    --add retention.ms=31536000000
```

> 31.536.000.000 ms = 365 días.

Verifica el cambio:

```bash
kafka-cli/describe-topic.sh novatech.audit.events | grep retention.ms
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió el valor? | |
| ¿El `ConfigSource` cambió? (ahora debería ser `DYNAMIC_TOPIC_CONFIG`) | |
| ¿El cambio requiere reiniciar el clúster? | |

---

## Actividad 2: Aumentar particiones (caso ops GPS)

**ADVERTENCIA**: aumentar particiones es operacionalmente delicado. Lo veremos primero, y después analizaremos sus consecuencias.

Verifica las particiones actuales:

```bash
kafka-cli/describe-topic.sh novatech.gps.realtime | head -3
```

Auméntalas a 18:

```bash
kafka-cli/alter-topic-partitions.sh novatech.gps.realtime 18
```

Verifica:

```bash
kafka-cli/describe-topic.sh novatech.gps.realtime | head -25
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Ahora cuántas particiones? | |
| ¿Las nuevas particiones (12-17) tienen mensajes? | |
| ¿Quién es el líder de la partición 12? | |

---

## Actividad 3: Lo que NO se puede hacer

Intenta **disminuir** las particiones:

```bash
kafka-cli/alter-topic-partitions.sh novatech.gps.realtime 6
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué error apareció? | |
| ¿Por qué Kafka no permite disminuir particiones? | |

> **Pista conceptual**: si una clave NVT-1001 estaba en partición 14 y disminuyeras a 6 particiones, ¿dónde irían sus mensajes futuros? ¿Y sus mensajes pasados? El orden por clave se rompería irremediablemente.

---

## Actividad 4: Eliminar overrides (volver al default)

Recuperaste cordura y quieres devolver `novatech.audit.events` a su retención original (90 días, que de hecho era un override). Para que vuelva al **default del broker**:

```bash
kafka-cli/alter-topic-config.sh novatech.audit.events --delete retention.ms
```

Verifica:

```bash
kafka-cli/describe-topic.sh novatech.audit.events | grep retention.ms
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál es el `retention.ms` ahora? | |
| ¿Qué `ConfigSource` tiene? | |

> **Pista**: el default de Kafka es `604800000` ms (7 días). Recuperaste cordura **demasiado**: ahora son 7 días. El CTO no estará feliz. Reaplícale 90 días para dejar el lab consistente:
> ```bash
> kafka-cli/alter-topic-config.sh novatech.audit.events --add retention.ms=7776000000
> ```

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Modificar configs en caliente | Cambiaste retention de 90 a 365 días sin downtime |
| Aumentar particiones | Subiste de 12 a 18 |
| Disminuir particiones (no se puede) | Probaste y fallaste, intencionalmente |
| Eliminar overrides | El tópico vuelve al default del broker |

---

## Siguiente paso

Continúa con [Parte 4: Producción y consumo masivo](04-produccion-y-consumo-masivo.md).
