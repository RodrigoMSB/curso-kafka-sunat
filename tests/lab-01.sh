#!/bin/bash
# E2E instructor · Lab 01 - Inicialización KRaft (build-your-own: despliega la solución)
# Nota: la solución de 1 broker nombra al contenedor 'kafka-broker' (singular).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Puertos propios del e2e, para no chocar con un cluster ya levantado.
puertos_e2e_brokers || exit 1
PROY="$(proyecto_e2e 01)"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-01-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro el lab 01"; exit 1; }
cd "$LAB_DIR"

SOL_COMPOSE="$(find soluciones -name 'docker-compose*.yml' 2>/dev/null | head -1)"
[ -n "$SOL_COMPOSE" ] || { echo "Sin compose de solución en lab 01"; exit 1; }

trap 'byo_teardown "$LAB_DIR" "$SOL_COMPOSE" "$PROY"' EXIT

test_start "Lab 01 - Inicializacion KRaft (solucion de referencia)"

docker compose -f "$SOL_COMPOSE" -p "$PROY" up -d >/dev/null 2>&1
wait_for_broker_api kafka-broker kafka-broker:29092 150 || abort_test "el broker de la solución no respondió"
_pass "broker de la solución arriba y respondiendo"

Q=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker \
    kafka-metadata-quorum --bootstrap-server kafka-broker:29092 describe --status 2>/dev/null)
assert_contains "$Q" "LeaderId" "quórum KRaft con líder"

MARK="$(new_mark)"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker kafka-topics \
    --bootstrap-server kafka-broker:29092 --create --topic "$MARK" --partitions 1 --replication-factor 1 >/dev/null 2>&1
produce_marked kafka-broker kafka-broker:29092 "$MARK" "$MARK" 3
GOT=$(consume_count_mark kafka-broker kafka-broker:29092 "$MARK" "$MARK")
assert_eq 3 "$GOT" "produce/consume en RF=1 (3/3 marcas)"

bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el 90 del alumno aprueba sobre la solución viva"

test_end; exit $?
