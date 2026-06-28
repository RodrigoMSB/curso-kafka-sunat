# Parte 4: Retención por tiempo en vivo

## Objetivo

Ver con tus propios ojos cómo Kafka elimina mensajes viejos según `retention.ms`. Usar un tópico con retención muy corta (60 segundos) para que el efecto sea observable.

## Contexto

`retention.ms` define cuánto tiempo se conservan los mensajes después de cerrar el segmento. Combinado con `segment.ms` (cuán seguido se cierran segmentos), determina cuándo desaparecen los mensajes viejos.

---

## Actividad 1: Estado del tópico efímero

```bash
kafka-cli/describe-topic.sh novatech.lab05.efimero | head -10
```

Verifica que tiene:
- `retention.ms=60000` (60 segundos)
- `segment.ms=10000` (segmentos de 10 segundos)

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuánto duran los mensajes en este tópico? | |
| ¿Por qué `segment.ms` corto importa? | |

> **Pista**: Kafka NO borra mensajes individuales. Borra **segmentos completos** cuando todos sus mensajes superan retention.ms. Si segment.ms es muy largo, los mensajes nuevos quedan en el mismo segmento que los viejos y nada se borra hasta que TODO el segmento expire.

---

## Actividad 2: Producir 100 mensajes

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 100
```

Verifica el tamaño:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero \
    --time -1
```

Anota el offset máximo de cualquier partición. Llamémoslo `OFFSET_INICIAL`.

| Métrica | Valor |
|---------|-------|
| OFFSET_INICIAL (máximo de cualquier partición) | |
| Hora de la producción | |

---

## Actividad 3: Esperar 90 segundos y verificar

Espera 90 segundos (1.5x el retention). Mientras esperas, puedes hacer otras cosas. Pon un timer.

Después de 90 segundos:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero \
    --time -2
```

Esto muestra el offset MÁS ANTIGUO disponible (`--time -2`). Si los mensajes se eliminaron, este offset será mayor que 0.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál es el offset más antiguo disponible ahora? | |
| ¿Se eliminaron mensajes? | |
| Si NO se eliminaron, ¿por qué crees que es? | |

---

## Actividad 4: Provocar más segmentos

A veces los segmentos no se cierran si no hay actividad. Vamos a forzar más rotación produciendo en intervalos:

```bash
for i in 1 2 3 4 5 6; do
    kafka-cli/produce-bulk.sh novatech.lab05.efimero 50
    echo "Esperando 15 segundos..."
    sleep 15
done
```

Esto produce 50 mensajes cada 15 segundos durante ~90 segundos. Cada `segment.ms=10000` debería cerrar segmentos.

Después:

```bash
# Offsets más antiguos
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero \
    --time -2

# Offsets más nuevos
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero \
    --time -1
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Offset más antiguo | |
| Offset más nuevo | |
| Mensajes "vivos" (resta) | |
| ¿Hubo eliminación? | |

---

## Actividad 5: Verificación visual en Kafbat UI

Abre **http://localhost:8090** > Topics > `novatech.lab05.efimero` > Overview.

Observa el tamaño en disco. Compáralo con `novatech.lab05.resiliente` (que tiene retención por defecto, 7 días).

| Pregunta | Tu respuesta |
|----------|-------------|
| Tamaño aproximado de `efimero` | |
| Tamaño aproximado de `resiliente` | |
| ¿Cuál ocupa más? ¿Por qué? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| `retention.ms` | Esperaste 90s y viste mensajes desaparecer |
| `segment.ms` | Entendiste que el borrado es por segmentos completos |
| Offset earliest vs latest | Usaste `--time -2` y `--time -1` |
| Espacio en disco | Comparaste tópicos con retenciones distintas |

---

## Siguiente paso

Continúa con [Parte 5: Desafío de compactación y tombstones](05-desafio-compactacion-y-tombstones.md).
