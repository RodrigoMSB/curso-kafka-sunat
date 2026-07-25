#!/bin/bash
# E2E instructor · Lab 05 - Operación de tópicos
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-05-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 05"; exit 1; }

trap 'lab_teardown "$LAB_DIR"' EXIT

test_start "Lab 05 - Operacion de topicos"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

BOOT="kafka-broker-1:29092"
KT() { MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" "$@"; }

bash bin/start-lab.sh >/dev/null 2>&1
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
_pass "clúster arriba (3 brokers healthy)"

MARK="$(new_mark)"
ETOPIC="${MARK}"   # new_mark ya devuelve 'e2e-<ts>-<rand>'

# Crear tópico efímero con 3 particiones, RF=3
KT --create --topic "$ETOPIC" --partitions 3 --replication-factor 3 >/dev/null 2>&1
P=$(KT --describe --topic "$ETOPIC" 2>/dev/null | grep -cE 'Partition: [0-9]+')
assert_eq 3 "$P" "tópico efímero creado con 3 particiones ($ETOPIC)"

# Aumentar particiones a 6
KT --alter --topic "$ETOPIC" --partitions 6 >/dev/null 2>&1
P2=$(KT --describe --topic "$ETOPIC" 2>/dev/null | grep -cE 'Partition: [0-9]+')
assert_eq 6 "$P2" "particiones aumentadas de 3 a 6"

# Borrar el tópico efímero
KT --delete --topic "$ETOPIC" >/dev/null 2>&1
sleep 2
if KT --list 2>/dev/null | grep -q "^${ETOPIC}$"; then GONE="no"; else GONE="yes"; fi
assert_eq "yes" "$GONE" "tópico efímero eliminado"

# El 90 del alumno también debe aprobar sobre el clúster vivo
bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el validador del alumno (90) aprueba sobre el lab vivo"

test_end; exit $?
