# Parte 1: Estrategias de asignación de particiones

## Objetivo

Comparar las 4 estrategias de asignación de Kafka (Range, RoundRobin, Sticky, CooperativeSticky) y entender cuándo conviene cada una.

## Contexto

Cuando varios consumers se unen a un grupo, Kafka asigna las particiones entre ellos usando una **estrategia**. La elección importa porque:
- Algunas son más equitativas
- Otras minimizan el rebalanceo
- La moderna (CooperativeSticky) permite rebalanceo INCREMENTAL sin parar todo

---

## Actividad 1: Estrategia Range (la legacy)

Asegúrate de que el tópico `novatech.lab07.eventos` existe (12 particiones):

```bash
kafka-cli/describe-topic.sh novatech.lab07.eventos | head -3
```

Abre **3 terminales**. En cada una:

```bash
kafka-cli/consume-with-strategy.sh --group test-range --strategy range
```

Espera ~10 segundos y, en una **cuarta terminal**, verifica la asignación:

```bash
kafka-cli/describe-group.sh test-range
```

### Anota

| Consumer | Particiones asignadas |
|----------|----------------------|
| 1 | |
| 2 | |
| 3 | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántas particiones tiene cada consumer? | |
| ¿Es una distribución equitativa? | |

> **Pista**: Range asigna particiones contiguas. Con 12 particiones y 3 consumers, asigna [0-3], [4-7], [8-11]. Cuando hay múltiples tópicos, este algoritmo puede ser injusto si uno tiene más particiones.

Cierra las 3 terminales con Ctrl+C.

---

## Actividad 2: Estrategia RoundRobin

```bash
# 3 terminales, todas con:
kafka-cli/consume-with-strategy.sh --group test-roundrobin --strategy roundrobin
```

Verifica:
```bash
kafka-cli/describe-group.sh test-roundrobin
```

| Consumer | Particiones |
|----------|-------------|
| 1 | |
| 2 | |
| 3 | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las particiones están más distribuidas? | |
| ¿Diferencia clave vs Range? | |

> **Pista**: RoundRobin asigna en intervalos: 1ro al consumer 1, 2do al 2, 3ro al 3, 4to al 1... Con 12 particiones y 3 consumers: [0,3,6,9], [1,4,7,10], [2,5,8,11].

Cierra las 3 terminales.

---

## Actividad 3: Estrategia Sticky

```bash
# 3 terminales:
kafka-cli/consume-with-strategy.sh --group test-sticky --strategy sticky
```

Verifica con `describe-group.sh test-sticky`. Anota.

Ahora, agrega un **4to consumer** en otra terminal:
```bash
kafka-cli/consume-with-strategy.sh --group test-sticky --strategy sticky
```

Espera ~5 segundos para el rebalanceo y verifica de nuevo:
```bash
kafka-cli/describe-group.sh test-sticky
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Antes: particiones por consumer | |
| Después de agregar el 4to: particiones por consumer | |
| ¿Cuántas particiones cambiaron de dueño? | |
| ¿Qué tiene de bueno minimizar la re-asignación? | |

> **Pista**: Sticky intenta MANTENER la asignación previa lo más posible. Solo mueve las particiones necesarias. Range/RoundRobin re-asignan TODO desde cero.

Cierra todas las terminales.

---

## Actividad 4: CooperativeSticky (la moderna)

```bash
# 3 terminales:
kafka-cli/consume-with-strategy.sh --group test-cooperative --strategy cooperative
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Distribución similar a Sticky? | |
| ¿Diferencia con Sticky? | |

> **Pista**: CooperativeSticky permite rebalanceo INCREMENTAL: solo los consumers afectados pausan, los otros siguen procesando. Sticky requiere "stop-the-world".

Cierra todas las terminales.

---

## Conclusiones

| Estrategia | Mejor para... | Defecto |
|-----------|--------------|---------|
| Range | Casos simples con 1 tópico | Injusta con múltiples tópicos |
| RoundRobin | Distribución pareja | Re-asigna todo en cada rebalanceo |
| Sticky | Minimizar re-asignación | Aún requiere stop-the-world |
| CooperativeSticky | **Producción moderna** | Más complejo |

---

## Siguiente paso

Continúa con [Parte 2: Lag y diagnóstico](02-lag-y-diagnostico.md).
