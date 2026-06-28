# Parte 3: Recuperación y catch-up

## Objetivo

Observar cómo los brokers que vuelven a la vida hacen catch-up y se reincorporan al ISR. Medir cuánto tarda esto bajo carga.

## Contexto

Cuando un broker cae y vuelve, no recupera datos automáticamente: tiene que **descargarlos del líder actual**. Mientras está atrasado, está fuera del ISR. Cuando se pone al día, el líder lo reincorpora.

---

## Actividad 1: Llenar el tópico mientras un broker está caído

Asegúrate de que los 3 brokers están vivos:

```bash
kafka-cli/describe-topic.sh novatech.lab05.resiliente | head -3
```

Tumba el broker 2:

```bash
bin/kill-broker.sh 2
```

Verifica que está fuera del ISR:

```bash
kafka-cli/describe-topic.sh novatech.lab05.resiliente | head -10
```

Produce 5.000 mensajes (mientras el broker 2 está abajo):

```bash
kafka-cli/produce-bulk.sh novatech.lab05.resiliente 5000 --key-pattern NVT
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La producción funcionó normalmente? | |
| ¿Cuánto tardó (segundos)? | |

---

## Actividad 2: Revivir y observar el catch-up

Antes de revivir, abre el monitor en una **terminal separada**:

```bash
kafka-cli/watch-isr.sh novatech.lab05.resiliente 1
```

Y en otra terminal:

```bash
bin/revive-broker.sh 2
```

Observa el monitor. **Cuenta cuántos segundos tarda el broker 2 en aparecer de nuevo en el ISR de TODAS las particiones**.

| Pregunta | Tu respuesta |
|----------|-------------|
| Tiempo aproximado de catch-up | |
| ¿El broker 2 entró al ISR de todas las particiones simultáneamente, o de a una? | |
| ¿Recuperó el rol de líder en alguna partición, o se quedó como follower? | |

---

## Actividad 3: Verificar que NO se perdieron mensajes

Cuenta los mensajes en el tópico:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.resiliente \
    --time -1
```

Suma los offsets de las 6 particiones.

| Pregunta | Tu respuesta |
|----------|-------------|
| Total de mensajes en el tópico | |
| ¿Coincide con los 5.000 producidos + cualquier otro mensaje previo? | |
| ¿Por qué los mensajes producidos durante la caída no se perdieron? | |

> **Pista**: con `acks=all` y MIR=2, las escrituras se confirmaron solo cuando 2 réplicas (broker-1 y broker-3) las recibieron. Cuando broker-2 volvió, descargó esos mensajes del líder.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Catch-up automático | Observaste cómo broker 2 recuperó datos sin intervención |
| Tiempo de catch-up | Medido bajo carga real |
| Durabilidad | Confirmaste que no se perdieron mensajes |
| Estabilidad de líder | El nuevo líder se mantiene incluso tras la recuperación |

---

## Siguiente paso

Continúa con [Parte 4: Retención por tiempo en vivo](04-retencion-por-tiempo-en-vivo.md).
