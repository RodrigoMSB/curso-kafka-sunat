#!/bin/bash
# E2E instructor · Lab 06 - Producción/consumo CLI
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

LAB_DIR=""
for d in "$HERE/../labs/"lab-06-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 06"; exit 1; }

trap 'lab_teardown "$LAB_DIR"' EXIT

test_start "Lab 06 - Produccion/consumo CLI"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
# Tópico real del lab (lo crea init-events-topic.sh); el TOPIC_NAME del .env no aplica aquí.
TOPIC="novatech.fleet.events"
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

bash bin/start-lab.sh >/dev/null 2>&1
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
_pass "clúster arriba (3 brokers healthy)"

MARK="$(new_mark)"
produce_marked kafka-broker-1 kafka-broker-1:29092 "$TOPIC" "$MARK" 5
GOT=$(consume_count_mark kafka-broker-1 kafka-broker-1:29092 "$TOPIC" "$MARK")
assert_eq 5 "$GOT" "consumo verificado de mis 5 marcas ($MARK)"

# El 90 del alumno también debe aprobar sobre el clúster vivo (integración de los dos niveles)
bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el validador del alumno (90) aprueba sobre el lab vivo"

test_end; exit $?
