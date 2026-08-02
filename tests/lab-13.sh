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
RC=$(running_count)
assert_ge "$RC" 2 "connector y task en estado RUNNING (${RC} RUNNING)"

# 4. El tópico destino recibe registros desde postgres
GOT=$(docker exec kafka-broker-1 bash -c \
    "kafka-console-consumer --bootstrap-server kafka-broker-1:29092 --topic $DEST_TOPIC --from-beginning --timeout-ms 20000 2>/dev/null | grep -c ." )
assert_ge "$GOT" 1 "el tópico ${DEST_TOPIC} recibió registros del source ($GOT)"

# El 90 del alumno también debe aprobar sobre el lab vivo
bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el validador del alumno (90) aprueba sobre el lab vivo"

test_end; exit $?
