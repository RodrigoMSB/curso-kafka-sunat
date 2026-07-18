# Material fuera de alcance — Lab 05 SUNAT

Material proveniente del laboratorio base (curso 28h) que queda **fuera del alcance
de 60 minutos** del SUNAT Lab 05 «Operación de tópicos». Se preserva intacto como
insumo para usos posteriores:

- `guia/04-produccion-y-consumo-masivo.md` — throughput y consumo masivo (pertenece
  conceptualmente al Lab 07, Pruebas de rendimiento).
- `guia/05-desafio-rf-y-eliminacion.md` — cambio de factor de replicación y eliminación (desafío).
- `guia/05-desafio-compactacion-y-tombstones.md` — compactación y tombstones (desafío).
- `kafka-cli/` — scripts usados solo por el material anterior.
- `soluciones/respuestas-desafio.md` — solución del desafío de RF.

No forma parte de la secuencia evaluable del Lab 05.

## Nota técnica para el Lab 07 (rendimiento)

El wrapper `kafka-cli/perf-test.sh` no expone el flag `--acks`, por lo que no permite comparar `acks=all` vs `acks=1` directamente. Para esa comparación: usar `kafka-producer-perf-test` directo en el contenedor con `--producer-props acks=N`, o agregar `--acks` al wrapper al construir el Lab 07.

## Nota técnica para el desafío de RF

El desafío de RF usa `kafka-reassign-partitions` (plan de reasignación en JSON). Si falla con `Reassignment of partition X failed`, la causa típica es que los brokers especificados en el JSON no existen o no están vivos. Verificar IDs de brokers vivos con `kafka-broker-api-versions`.
