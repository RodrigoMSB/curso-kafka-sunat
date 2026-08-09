#!/bin/bash
# E2E instructor · Lab 08 - Brokers en caliente (config dinámica, add/reassign/drain)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 08)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-08-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 08"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 08 - Brokers en caliente"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

BOOT="kafka-broker-1:29092"
TOPIC="novatech.lab08.pedidos"

# ¿Está el broker 4 en la lista de réplicas del tópico? -> imprime yes/no
has_broker4() {
    docker exec kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" --describe --topic "$TOPIC" 2>/dev/null \
        | grep -oE 'Replicas: [0-9,]+' | grep -oE '[0-9]+' | grep -qx 4 && echo yes || echo no
}

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
_pass "clúster arriba (3 brokers healthy)"

# 1. Reconfiguración en caliente: num.replica.fetchers=2 (tope válido en Kafka 4.2)
bash kafka-cli/alter-broker-config.sh 1 num.replica.fetchers=2 >/dev/null 2>&1
assert_success $? "alter-broker-config acepta num.replica.fetchers=2 en caliente"

# 2. Agregar broker-4 (profile scale) y verlo en el clúster
bash kafka-cli/add-broker.sh >/dev/null 2>&1
wait_for_container kafka-broker-4 120 || abort_test "broker-4 no llegó a healthy/running"
BROKERS=$(bash kafka-cli/list-brokers.sh 2>/dev/null || true)
assert_contains "$BROKERS" "kafka-broker-4" "broker-4 aparece en list-brokers"

# 3. Reasignar a 4 brokers → el broker 4 recibe réplicas
bash kafka-cli/reassign-partitions.sh "$TOPIC" 1,2,3,4 >/dev/null 2>&1
assert_eq "yes" "$(has_broker4)" "tras reasignar a 1,2,3,4 el broker 4 tiene réplicas"

# 4. Drenar el broker 4 → deja de tener réplicas
bash kafka-cli/drain-broker.sh "$TOPIC" 1,2,3 >/dev/null 2>&1
assert_eq "no" "$(has_broker4)" "tras drenar a 1,2,3 el broker 4 queda sin réplicas"

# El 90 del alumno también debe aprobar sobre el clúster vivo (estado base de 3 brokers)
# La salida del validador del alumno NO se tira: si el 90 aprueba diciendo
# algo falso, o falla, el e2e tiene que mostrarlo. Era el ultimo vector de
# verde con material roto (SPEC-66 F1).
SALIDA_90=$(bash bin/90-test-lab.sh 2>&1); RC90=$?
printf '%s\n' "$SALIDA_90"
assert_success "$RC90" "el validador del alumno (90) aprueba sobre el lab vivo"
assert_contains "$SALIDA_90" "LAB EN BUEN ESTADO" "el 90 imprime su linea de conteo (se lee, no se asume)"

test_end; exit $?
