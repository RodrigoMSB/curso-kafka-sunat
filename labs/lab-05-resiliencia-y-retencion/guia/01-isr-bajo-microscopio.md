# Parte 1: El ISR bajo el microscopio

## Objetivo

Entender cómo el ISR (In-Sync Replicas) es la lista de brokers que están sincronizados con el líder de cada partición. Observar cómo cambia cuando un broker se cae.

## Contexto

El ISR es el corazón de la durabilidad en Kafka. Cuando produces con `acks=all`, el líder espera que TODAS las réplicas en ISR confirmen antes de responder al productor. Si una réplica se atrasa demasiado, sale del ISR. Si vuelve, entra de nuevo.

---

## Actividad 1: Estado inicial del ISR

Mira el ISR del tópico `novatech.lab05.resiliente`:

```bash
kafka-cli/describe-topic.sh novatech.lab05.resiliente
```

### Anota

| Partición | Leader | Replicas | ISR |
|-----------|--------|----------|-----|
| 0 | | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El ISR coincide con Replicas en TODAS las particiones? | |
| ¿Qué significa que coincidan? | |
| ¿Qué `min.insync.replicas` está configurado para este tópico? | |

---

## Actividad 2: Productor continuo en background

Abre **terminal A** y produce mensajes continuamente:

```bash
kafka-cli/produce-continuous.sh novatech.lab05.resiliente --rate 500 --key-pattern NVT
```

Verás `→ enviado #1`, `→ enviado #2`, etc. cada 500ms. Déjalo corriendo.

---

## Actividad 3: Monitor de ISR en otra terminal

Abre **terminal B** y monitorea el ISR cada 1 segundo:

```bash
kafka-cli/watch-isr.sh novatech.lab05.resiliente 1
```

Verás la salida actualizándose cada segundo. **Mantén las 2 terminales visibles a la vez**.

---

## Actividad 4: Tumbar un broker mientras se produce

En una **tercera terminal**, tumba el broker 2:

```bash
bin/kill-broker.sh 2
```

Vuelve a las terminales A y B. **Observa atentamente** durante 30 segundos.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La terminal A (productor) siguió enviando mensajes? | |
| ¿En la terminal B (monitor) cambió el ISR? ¿Qué pasó? | |
| ¿Cuántos brokers quedan en el ISR de cada partición? | |
| ¿Las particiones cuyo líder era el broker 2 cambiaron de líder? | |

---

## Actividad 5: Revivir el broker

```bash
bin/revive-broker.sh 2
```

Espera ~30 segundos. Sigue mirando la terminal B.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El broker 2 volvió al ISR? | |
| ¿Recuperó su rol de líder en alguna partición? | |
| ¿O se quedó como follower? | |

---

## Cierre de la actividad

Cierra el productor (terminal A) con Ctrl+C, y el monitor (terminal B) con Ctrl+C.

---

## Conclusiones

| Concepto | Lo aprendiste viendo... |
|----------|------------------------|
| ISR completo | Las 3 réplicas sincronizadas en cada partición |
| ISR reducido | Cuando un broker cayó, las réplicas en ese broker salieron del ISR |
| Re-elección de líder | Las particiones cuyo líder murió eligieron uno nuevo entre los survivientes |
| Recuperación | Al revivir el broker, sus réplicas hicieron catch-up y volvieron al ISR |

---

## Siguiente paso

Continúa con [Parte 2: Carrera contra `min.insync.replicas`](02-carrera-contra-min-insync.md).
