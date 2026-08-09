#!/bin/bash
# E2E instructor · Lab 12 - ksqlDB
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 12)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-12-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 12"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 12 - ksqlDB"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh ksql-cli/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

KSQL="http://localhost:8088"
TOPIC="novatech.lab10.pedidos"

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"

# ksqlDB tarda en servir: poll a /info hasta 150s
W=0; until curl -sf --max-time 5 "${KSQL}/info" >/dev/null 2>&1 || [ "$W" -ge 150 ]; do sleep 5; W=$((W+5)); done
curl -sf --max-time 5 "${KSQL}/info" >/dev/null 2>&1 || abort_test "ksqlDB no respondió /info en 150s"
_pass "clúster + ksqlDB server arriba"

# 1. Sembrar datos Avro (3 pedidos) para que el stream tenga filas
for id in 1 2 3; do
    bash kafka-cli/produce-pedido-avro.sh "$id" 1001 "Caja premium" 10 25000.00 pendiente >/dev/null 2>&1
done

# 2. Crear el stream (Actividad del lab) sobre el tópico Avro
docker exec ksqldb-cli ksql "http://ksqldb-server:8088" --execute \
  "CREATE STREAM pedidos_stream (id INT, cliente_id INT, producto VARCHAR, cantidad INT, monto DOUBLE, estado VARCHAR) WITH (KAFKA_TOPIC='${TOPIC}', VALUE_FORMAT='AVRO');" >/dev/null 2>&1

# 3. SHOW STREAMS (script del lab) incluye el stream creado
STREAMS=$(bash ksql-cli/show-streams.sh 2>/dev/null || true)
assert_contains "$STREAMS" "PEDIDOS_STREAM" "SHOW STREAMS incluye PEDIDOS_STREAM"

# 4. SELECT push con LIMIT 1 (REST /query, acotado con --max-time) devuelve una fila
QRESP=$(curl -sf --max-time 25 -X POST "${KSQL}/query" \
    -H 'Content-Type: application/vnd.ksql.v1+json' \
    -d '{"ksql":"SELECT * FROM pedidos_stream EMIT CHANGES LIMIT 1;","streamsProperties":{"ksql.streams.auto.offset.reset":"earliest"}}' 2>/dev/null || true)
assert_contains "$QRESP" "Caja premium" "SELECT EMIT CHANGES LIMIT 1 devuelve una fila con datos"

# El 90 del alumno también debe aprobar sobre el lab vivo
# La salida del validador del alumno NO se tira: si el 90 aprueba diciendo
# algo falso, o falla, el e2e tiene que mostrarlo. Era el ultimo vector de
# verde con material roto (SPEC-66 F1).
SALIDA_90=$(bash bin/90-test-lab.sh 2>&1); RC90=$?
printf '%s\n' "$SALIDA_90"
assert_success "$RC90" "el validador del alumno (90) aprueba sobre el lab vivo"
assert_contains "$SALIDA_90" "LAB EN BUEN ESTADO" "el 90 imprime su linea de conteo (se lee, no se asume)"

test_end; exit $?
