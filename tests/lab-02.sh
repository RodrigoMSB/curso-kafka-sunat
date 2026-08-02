#!/bin/bash
# E2E instructor · Lab 02 - Quórum y resiliencia (build-your-own: despliega la solución)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Puertos propios del e2e, para no chocar con un cluster ya levantado.
puertos_e2e_brokers || exit 1
PROY="$(proyecto_e2e 02)"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-02-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro el lab 02"; exit 1; }
cd "$LAB_DIR"

SOL_COMPOSE="$(find soluciones -name 'docker-compose*.yml' 2>/dev/null | head -1)"
[ -n "$SOL_COMPOSE" ] || { echo "Sin compose de solución en lab 02"; exit 1; }

trap 'byo_teardown "$LAB_DIR" "$SOL_COMPOSE" "$PROY"' EXIT

test_start "Lab 02 - Quorum y resiliencia (solucion de referencia)"

BOOT="kafka-broker-1:29092"
BOOT_SURV="kafka-broker-1:29092,kafka-broker-2:29093"

levantar_compose "$SOL_COMPOSE" "$PROY" kafka-broker-1 kafka-broker-2 kafka-broker-3 || abort_test "no se pudo levantar el entorno del lab"
wait_for_broker_api kafka-broker-1 "$BOOT" 150 || abort_test "el clúster de la solución no respondió"
wait_for_broker_api kafka-broker-2 kafka-broker-2:29093 60 || abort_test "broker-2 no respondió"
wait_for_broker_api kafka-broker-3 kafka-broker-3:29094 60 || abort_test "broker-3 no respondió"
_pass "clúster de 3 nodos arriba y respondiendo"

# Quórum con líder y 3 voters
ST=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 \
     kafka-metadata-quorum --bootstrap-server "$BOOT" describe --status 2>/dev/null)
REP=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 \
     kafka-metadata-quorum --bootstrap-server "$BOOT" describe --replication 2>/dev/null)
assert_contains "$ST" "LeaderId" "quórum KRaft con líder"
VOTERS=$(echo "$REP" | grep -cE '^[0-9]+[[:space:]]')
assert_ge "$VOTERS" 3 "el quórum tiene 3 voters ($VOTERS)"

# Tópico RF=3 creado ANTES del fallo
MARK="$(new_mark)"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-topics \
    --bootstrap-server "$BOOT" --create --topic "$MARK" --partitions 3 --replication-factor 3 >/dev/null 2>&1
prod() {  # <start> <end> <bootstrap>
    local s="$1" e="$2" b="$3" i
    for i in $(seq "$s" "$e"); do echo "${MARK}-${i}"; done | \
        MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= kafka-broker-1 kafka-console-producer \
        --bootstrap-server "$b" --command-property acks=all --topic "$MARK" >/dev/null 2>&1
}
prod 1 3 "$BOOT"

# RESILIENCIA: cae broker-3; el quórum sigue con líder y se sigue produciendo
docker stop kafka-broker-3 >/dev/null 2>&1
sleep 8
ST2=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 \
      kafka-metadata-quorum --bootstrap-server "$BOOT_SURV" describe --status 2>/dev/null)
assert_contains "$ST2" "LeaderId" "tras caer un nodo, el quórum sigue con líder (2/3)"

prod 4 6 "$BOOT_SURV"   # producción DURANTE el fallo
GOT=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 bash -c \
    "kafka-console-consumer --bootstrap-server $BOOT_SURV --topic $MARK --from-beginning --timeout-ms 8000 2>/dev/null | grep -c '^${MARK}-'")
assert_eq 6 "$GOT" "produce/consume sigue con un nodo caído (6/6 marcas)"

# Recuperación
docker start kafka-broker-3 >/dev/null 2>&1
wait_for_broker_api kafka-broker-3 kafka-broker-3:29094 90 || abort_test "broker-3 no se recuperó"
_pass "broker-3 recuperado (3 nodos de nuevo)"

bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el 90 del alumno aprueba sobre el clúster recuperado"

test_end; exit $?
