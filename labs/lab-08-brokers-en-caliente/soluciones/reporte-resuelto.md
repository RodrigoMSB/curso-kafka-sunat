# Lab 08 — Reporte resuelto (solución de referencia)

> Los valores numéricos (distribución exacta de particiones, timings) dependen de la corrida; aquí se dan los conceptos y los resultados esperados.

## Parte 1
- `num.replica.fetchers`: valor por defecto **1**, origen `DEFAULT_CONFIG` (no hay override aún).
- La config `default` está vacía al inicio porque **no se ha fijado ningún default dinámico cluster-wide**; solo aparecen overrides explícitos.

## Parte 2
- `num.replica.fetchers=4`: el broker **NO** se reinicia (uptime intacto). Origen pasa a `DYNAMIC_BROKER_CONFIG`.
- `log.retention.ms=3600000`: aparece en la config `default`, afecta a **todos** los brokers que no tengan override propio.
- `process.roles`: Kafka rechaza el cambio — es **read-only**, fijada al arranque. Tiene sentido porque cambiar el rol de un nodo (broker↔controller) en caliente rompería el quórum y la identidad del nodo.

## Parte 3
- Tras `add-broker.sh`, el broker 4 aparece en `list-brokers` pero **sin particiones**: agregar capacidad no mueve datos.
- Tras `reassign-partitions.sh ... 1,2,3,4`, el broker 4 **sí** recibe particiones (el plan las redistribuye).
- La producción **no falla**: la reasignación copia réplicas en segundo plano y solo cambia el líder cuando la nueva réplica está in-sync. Por eso no hay downtime.

## Parte 4
- Tras `drain-broker.sh ... 1,2,3`, el broker 4 queda **sin particiones** (todas movidas a 1–3).
- Se drena antes de apagar porque apagar con réplicas vivas en el broker reduciría el ISR y podría dejar particiones bajo el mínimo.
- El quórum **no** se ve afectado: el broker 4 es broker-only, nunca fue voter del quórum de controladores (1,2,3).

## Desafío
- En un ciclo completo bien ejecutado **no hay pérdida de mensajes** (RF 3 + min.insync.replicas 2 lo garantizan).
- El paso más lento suele ser la **reasignación**, porque implica copiar datos entre brokers.

---

*Solución - Lab 08*
