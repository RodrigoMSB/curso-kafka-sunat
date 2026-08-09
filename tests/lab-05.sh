#!/bin/bash
# E2E instructor · Lab 05 - Operación de tópicos
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 05)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-05-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 05"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 05 - Operacion de topicos"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

BOOT="kafka-broker-1:29092"
KT() { MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" "$@"; }

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
_pass "clúster arriba (3 brokers healthy)"

MARK="$(new_mark)"
ETOPIC="${MARK}"   # new_mark ya devuelve 'e2e-<ts>-<rand>'

# Crear tópico efímero con 3 particiones, RF=3
KT --create --topic "$ETOPIC" --partitions 3 --replication-factor 3 >/dev/null 2>&1
medir KT --describe --topic "$ETOPIC"
P=$(printf '%s\n' "$MEDIDA" | grep -cE 'Partition: [0-9]+')
assert_conteo_eq 3 "$P" "tópico efímero creado con 3 particiones ($ETOPIC)"

# Aumentar particiones a 6
KT --alter --topic "$ETOPIC" --partitions 6 >/dev/null 2>&1
medir KT --describe --topic "$ETOPIC"
P2=$(printf '%s\n' "$MEDIDA" | grep -cE 'Partition: [0-9]+')
assert_conteo_eq 6 "$P2" "particiones aumentadas de 3 a 6"

# Borrar el tópico efímero
KT --delete --topic "$ETOPIC" >/dev/null 2>&1
sleep 2
if KT --list 2>/dev/null | grep -q "^${ETOPIC}$"; then GONE="no"; else GONE="yes"; fi
assert_eq "yes" "$GONE" "tópico efímero eliminado"

# El 90 del alumno también debe aprobar sobre el clúster vivo
# La salida del validador del alumno NO se tira: si el 90 aprueba diciendo
# algo falso, o falla, el e2e tiene que mostrarlo. Era el ultimo vector de
# verde con material roto (SPEC-66 F1).
SALIDA_90=$(bash bin/90-test-lab.sh 2>&1); RC90=$?
printf '%s\n' "$SALIDA_90"
assert_success "$RC90" "el validador del alumno (90) aprueba sobre el lab vivo"
assert_contains "$SALIDA_90" "LAB EN BUEN ESTADO" "el 90 imprime su linea de conteo (se lee, no se asume)"

test_end; exit $?
