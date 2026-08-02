#!/bin/bash
# E2E instructor · Lab 07 - Pruebas de rendimiento
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 07)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-07-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 07"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 07 - Pruebas de rendimiento"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

BENCH="novatech.tuning.bench"

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
_pass "clúster arriba (3 brokers healthy)"

# Producer perf con el script del lab → debe reportar records/sec
POUT=$(bash kafka-cli/perf-test.sh "$BENCH" 2000 2>&1 || true)
assert_contains "$POUT" "records/sec" "producer-perf-test devuelve throughput (records/sec)"

# Consumer perf con el script del lab (post-fix sin --threads) → métricas nMsg.sec
COUT=$(bash kafka-cli/consumer-perf-test.sh "$BENCH" 2000 2>&1 || true)
assert_contains "$COUT" "nMsg.sec" "consumer-perf-test devuelve métricas (nMsg.sec)"

# El 90 del alumno también debe aprobar sobre el clúster vivo
bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el validador del alumno (90) aprueba sobre el lab vivo"

test_end; exit $?
