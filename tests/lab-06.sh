#!/bin/bash
# E2E instructor · Lab 06 - Producción/consumo CLI
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 06)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-06-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 06"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 06 - Produccion/consumo CLI"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
# Tópico real del lab (lo crea init-events-topic.sh); el TOPIC_NAME del .env no aplica aquí.
TOPIC="novatech.fleet.events"
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
_pass "clúster arriba (3 brokers healthy)"

MARK="$(new_mark)"
produce_marked kafka-broker-1 kafka-broker-1:29092 "$TOPIC" "$MARK" 5
GOT=$(consume_count_mark kafka-broker-1 kafka-broker-1:29092 "$TOPIC" "$MARK")
assert_eq 5 "$GOT" "consumo verificado de mis 5 marcas ($MARK)"

# El 90 del alumno también debe aprobar sobre el clúster vivo (integración de los dos niveles)
# La salida del validador del alumno NO se tira: si el 90 aprueba diciendo
# algo falso, o falla, el e2e tiene que mostrarlo. Era el ultimo vector de
# verde con material roto (SPEC-66 F1).
SALIDA_90=$(bash bin/90-test-lab.sh 2>&1); RC90=$?
printf '%s\n' "$SALIDA_90"
assert_success "$RC90" "el validador del alumno (90) aprueba sobre el lab vivo"
assert_contains "$SALIDA_90" "LAB EN BUEN ESTADO" "el 90 imprime su linea de conteo (se lee, no se asume)"

test_end; exit $?
