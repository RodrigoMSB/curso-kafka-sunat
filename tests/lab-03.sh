#!/bin/bash
# E2E instructor · Lab 03 - Configuración de brokers (build-your-own: despliega la solución)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

LAB_DIR=""
for d in "$HERE/../labs/"lab-03-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro el lab 03"; exit 1; }
cd "$LAB_DIR"

SOL_COMPOSE="$(find soluciones -name 'docker-compose*.yml' 2>/dev/null | head -1)"
[ -n "$SOL_COMPOSE" ] || { echo "Sin compose de solución en lab 03"; exit 1; }

trap 'byo_teardown "$LAB_DIR" "$SOL_COMPOSE"' EXIT

test_start "Lab 03 - Configuracion de brokers (solucion de referencia)"

BOOT="kafka-broker-1:29092"

docker compose -f "$SOL_COMPOSE" up -d >/dev/null 2>&1
wait_for_broker_api kafka-broker-1 "$BOOT" 150 || abort_test "el clúster de la solución no respondió"
_pass "clúster de 3 nodos arriba y respondiendo"

# process.roles en el properties generado
ROLES=$(MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 bash -c 'grep -h process.roles /etc/kafka/*.properties' 2>/dev/null)
assert_contains "$ROLES" "broker,controller" "el properties generado declara process.roles=broker,controller"

# Configuración efectiva con orígenes
CFG=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-configs \
    --bootstrap-server "$BOOT" --describe --entity-type brokers --entity-name 1 --all 2>/dev/null)
assert_contains "$CFG" "STATIC_BROKER_CONFIG" "kafka-configs reporta orígenes STATIC_BROKER_CONFIG"
assert_contains "$CFG" "min.insync.replicas" "la config efectiva incluye min.insync.replicas"

bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el 90 del alumno aprueba sobre la solución viva"

test_end; exit $?
