# Parte 3: Consumer Groups y escalado horizontal

## Objetivo

Entender cómo Kafka reparte automáticamente las particiones entre los miembros de un mismo **consumer group**, permitiendo escalar horizontalmente el procesamiento de mensajes.

## Contexto

El área de **Alertas** de NovaTech recibe MUCHO volumen y un solo proceso no da abasto. Necesitamos repartir el trabajo entre varios consumidores que **colaboren** (no que dupliquen el trabajo).

Solución de Kafka: agruparlos en un **consumer group**. Dentro del grupo, las 6 particiones del tópico se reparten entre los miembros.

---

## Actividad 1: Un solo consumidor en el grupo

Abre **terminal A**:

```bash
kafka-cli/consume-as-group.sh --group alertas
```

En otra terminal, verifica el estado:

```bash
kafka-cli/describe-group.sh alertas
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene asignadas el único miembro del grupo? | |
| ¿Por qué? | |

---

## Actividad 2: Sumar un segundo consumidor al grupo

Sin cerrar la terminal A, abre **terminal B** con el MISMO grupo:

```bash
kafka-cli/consume-as-group.sh --group alertas
```

Espera ~5 segundos (Kafka tarda un momento en hacer el rebalanceo).

Ejecuta nuevamente:

```bash
kafka-cli/describe-group.sh alertas
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene cada miembro ahora? | |
| ¿Sumadas, dan 6? | |

---

## Actividad 3: Tres consumidores en el grupo

Abre **terminal C** con el mismo grupo:

```bash
kafka-cli/consume-as-group.sh --group alertas
```

Espera el rebalanceo y verifica:

```bash
kafka-cli/describe-group.sh alertas
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene cada miembro? | |
| ¿Es una distribución equitativa? | |

---

## Actividad 4: Producir mensajes y ver quién recibe qué

En una **cuarta terminal**, produce 6 mensajes con claves distintas para forzar distribución:

```bash
kafka-cli/produce-event.sh --key NVT-1001 "evento alfa"
kafka-cli/produce-event.sh --key NVT-1002 "evento bravo"
kafka-cli/produce-event.sh --key NVT-1003 "evento charlie"
kafka-cli/produce-event.sh --key NVT-1004 "evento delta"
kafka-cli/produce-event.sh --key NVT-1005 "evento echo"
kafka-cli/produce-event.sh --key NVT-1006 "evento foxtrot"
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cada terminal (A, B, C) recibió aproximadamente 2 mensajes cada una? | |
| ¿Algún mensaje fue recibido por más de una terminal del MISMO grupo? | |

> **Comparación**: en la Parte 2 (sin grupo), las 3 terminales recibieron TODOS los mensajes. En esta parte (mismo grupo), los mensajes se repartieron. Esa es la diferencia clave.

---

## Actividad 5: Demasiados consumidores

Abre **terminal D** y **terminal E** con el mismo grupo:

```bash
kafka-cli/consume-as-group.sh --group alertas
```
```bash
kafka-cli/consume-as-group.sh --group alertas
```

Verifica:

```bash
kafka-cli/describe-group.sh alertas
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene cada uno de los 5 miembros? | |
| ¿Hay miembros sin particiones asignadas? | |
| Si tuvieras 7 consumidores y 6 particiones, ¿qué pasaría con uno? | |

> **Regla**: Un miembro sin particiones está OCIOSO. Más consumidores que particiones es desperdicio.

---

## Actividad 6: Rebalanceo en vivo

Cierra **bruscamente** la terminal A (Ctrl+C).

Espera ~10 segundos y verifica:

```bash
kafka-cli/describe-group.sh alertas
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos miembros tiene ahora el grupo? | |
| ¿Las particiones que tenía A se redistribuyeron entre los demás? | |

**Verifica visualmente en Kafbat UI:**
1. Abre **http://localhost:8090**
2. Menú lateral > **Consumers** > clic en **alertas**
3. Verás los miembros restantes y sus particiones asignadas

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Consumer group | Lanzaste varios consumers con `--group alertas` |
| Reparto automático | Las 6 particiones se distribuyeron entre miembros |
| Cota máxima | Más consumers que particiones = ociosos |
| Rebalanceo | Mataste un consumer y los demás absorbieron sus particiones |

---

## Siguiente paso

Continúa con la [Parte 4: Offsets y Replay](04-offsets-y-replay.md).
