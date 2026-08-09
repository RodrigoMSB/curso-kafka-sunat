#!/bin/bash
# E2E instructor · Lab 13 - Kafka Connect (JDBC source)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 13)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-13-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 13"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 13 - Kafka Connect"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh connect-cli/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

CONNECT="http://localhost:8083"
CONN="novatech-source-pedidos"
DEST_TOPIC="novatech.lab09.pedidos"

running_count() {
    curl -sf --max-time 8 "${CONNECT}/connectors/${CONN}/status" 2>/dev/null \
        | grep -o '"state":"RUNNING"' | grep -c . || true
}

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
wait_for_container postgres 120 || abort_test "postgres no llegó a healthy"
wait_for_container kafka-connect 150 || abort_test "Kafka Connect no llegó a healthy"
_pass "clúster + postgres + Kafka Connect arriba"

# 1. Connect REST responde
curl -sf --max-time 8 "${CONNECT}/connectors" >/dev/null 2>&1
assert_success $? "Kafka Connect REST responde /connectors"

# 2. Crear el JDBC source connector con el script del lab
bash connect-cli/create-source.sh >/dev/null 2>&1
sleep 3

# 3. Connector y task en RUNNING (poll hasta 90s)
W=0
until [ "$(running_count)" -ge 2 ] || [ "$W" -ge 90 ]; do sleep 5; W=$((W+5)); done
# El poll de arriba usa running_count() a secas; para la asercion se vuelve a
# medir mostrando el diagnostico: un 0 por "Connect no responde" y un 0 por
# "el connector no arranco" son dos problemas distintos.
medir curl -sf --max-time 8 "${CONNECT}/connectors/${CONN}/status"
RC=$(printf '%s' "$MEDIDA" | grep -o '"state":"RUNNING"' | grep -c . || true)
assert_conteo_ge 2 "$RC" "connector y task en estado RUNNING (${RC} RUNNING)"

# 4. El tópico destino recibe registros desde postgres
medir docker exec kafka-broker-1 bash -c \
    "kafka-console-consumer --bootstrap-server kafka-broker-1:29092 --topic $DEST_TOPIC --from-beginning --timeout-ms 20000 | grep -c ."
GOT="$MEDIDA"
assert_conteo_ge 1 "$GOT" "el tópico ${DEST_TOPIC} recibió registros del source ($GOT)"

# El 90 del alumno también debe aprobar sobre el lab vivo
# La salida del validador del alumno NO se tira: si el 90 aprueba diciendo
# algo falso, o falla, el e2e tiene que mostrarlo. Era el ultimo vector de
# verde con material roto (SPEC-66 F1).
SALIDA_90=$(bash bin/90-test-lab.sh 2>&1); RC90=$?
printf '%s\n' "$SALIDA_90"
assert_success "$RC90" "el validador del alumno (90) aprueba sobre el lab vivo"
assert_contains "$SALIDA_90" "LAB EN BUEN ESTADO" "el 90 imprime su linea de conteo (se lee, no se asume)"

test_end; exit $?
