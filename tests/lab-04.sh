#!/bin/bash
# E2E instructor · Lab 04 - Listeners y advertised.listeners (build-your-own: despliega la solución)
# El listener EXTERNAL de la solución se anuncia como localhost:9092 → alcanzable desde el HOST
# (el cliente externo real). Un contenedor efímero NO puede usarlo (resolvería localhost a sí mismo),
# por eso la sonda externa se hace a nivel TCP desde el host, donde corre este e2e.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Puertos propios del e2e, para no chocar con un cluster ya levantado.
puertos_e2e_brokers || exit 1
PROY="$(proyecto_e2e 04)"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-04-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro el lab 04"; exit 1; }
cd "$LAB_DIR"

SOL_COMPOSE="$(find soluciones -name 'docker-compose*.yml' 2>/dev/null | head -1)"
[ -n "$SOL_COMPOSE" ] || { echo "Sin compose de solución en lab 04"; exit 1; }

trap 'byo_teardown "$LAB_DIR" "$SOL_COMPOSE" "$PROY"' EXIT

test_start "Lab 04 - Listeners y advertised (solucion de referencia)"

BOOT="kafka-broker-1:29092"
EXT_PORT="9092"

docker compose -f "$SOL_COMPOSE" -p "$PROY" up -d >/dev/null 2>&1
wait_for_broker_api kafka-broker-1 "$BOOT" 150 || abort_test "el clúster de la solución no respondió (interno)"
_pass "clúster de 3 nodos arriba (listener interno)"

# EXTERNAL alcanzable desde fuera de la red Docker (el host)
if (exec 3<>/dev/tcp/localhost/${EXT_PORT}) 2>/dev/null; then
    exec 3>&- 3<&- 2>/dev/null || true
    _pass "listener EXTERNAL alcanzable en localhost:${EXT_PORT} (desde el host)"
else
    _fail "listener EXTERNAL" "no responde en localhost:${EXT_PORT}"
fi

# Produce/consume por el listener interno
MARK="$(new_mark)"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-topics \
    --bootstrap-server "$BOOT" --create --topic "$MARK" --partitions 3 --replication-factor 3 >/dev/null 2>&1
produce_marked kafka-broker-1 "$BOOT" "$MARK" "$MARK" 3
GOT=$(consume_count_mark kafka-broker-1 "$BOOT" "$MARK" "$MARK")
assert_eq 3 "$GOT" "produce/consume por el listener interno (3/3 marcas)"

bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el 90 del alumno aprueba sobre la solución viva"

test_end; exit $?
