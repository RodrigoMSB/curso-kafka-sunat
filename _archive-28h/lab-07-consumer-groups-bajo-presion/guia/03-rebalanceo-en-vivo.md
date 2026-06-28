# Parte 3: Rebalanceo en vivo

## Objetivo

Observar y medir el tiempo de rebalanceo cuando un consumer se cae. Comparar el comportamiento entre estrategia clásica (eager) y cooperative.

## Contexto

Cuando un consumer abandona el grupo (crash, deploy, scale-down), Kafka redistribuye sus particiones. El **tiempo** que toma esto y el **comportamiento de los demás consumers** durante el rebalanceo dependen de la estrategia.

- **Eager** (Range, RoundRobin, Sticky): TODOS los consumers paran. Re-asignación completa. Más lento.
- **Cooperative**: solo los afectados paran. Re-asignación incremental. Más rápido.

---

## Actividad 1: Rebalanceo con estrategia EAGER

En **3 terminales**:
```bash
kafka-cli/consume-with-strategy.sh --group rebalance-eager --strategy range
```

Espera ~10s. Verifica:
```bash
kafka-cli/describe-group.sh rebalance-eager
```

Anota la asignación. Ahora **mata** la terminal A con Ctrl+C **bruscamente** (no graceful).

Inmediatamente verifica:
```bash
kafka-cli/describe-group.sh rebalance-eager
```

Repítelo cada 2 segundos hasta que se complete el rebalanceo.

| Métrica | Valor |
|---------|-------|
| Segundos hasta que aparece "Rebalancing..." | |
| Segundos hasta que termina el rebalanceo | |
| ¿Las terminales B y C estuvieron procesando durante el rebalanceo? | |

---

## Actividad 2: Rebalanceo con CooperativeSticky

Cierra todo. Lanza **3 consumers nuevos** con cooperative:
```bash
kafka-cli/consume-with-strategy.sh --group rebalance-coop --strategy cooperative
```

Verifica:
```bash
kafka-cli/describe-group.sh rebalance-coop
```

Mata uno (Ctrl+C). Mide el rebalanceo.

| Métrica | Valor |
|---------|-------|
| Segundos hasta completar rebalanceo | |
| ¿Las otras 2 terminales siguieron procesando? | |
| ¿Se notó "stop-the-world"? | |

---

## Actividad 3: Comparativa final

| Estrategia | Tiempo rebalanceo | ¿Stop-the-world? |
|-----------|-------------------|------------------|
| Eager (Range)        | | |
| CooperativeSticky    | | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál recomendarías para producción? | |
| ¿Por qué? | |
| ¿En qué caso usarías eager? | |

---

## Cierre

Cierra todas las terminales.

---

## Siguiente paso

Continúa con [Parte 4: Manejo manual de offsets](04-manejo-manual-de-offsets.md).
