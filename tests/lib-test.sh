#!/bin/bash
# ============================================================
# Harness E2E (instructor) - librería compartida (SUNAT)
# Aserciones + marcas únicas + produce/consume verificado + veredicto binario.
# La sourcean los tests/lab-NN.sh. No se ejecuta sola.
# Portable: bash 3.2 (macOS), sin GNU-ismos.
# ============================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

_PASS=0; _FAIL=0; _FAILURES=(); _LAB_NAME=""; _T0=0

test_start() {
    _LAB_NAME="$1"; _PASS=0; _FAIL=0; _FAILURES=(); _T0=$(date +%s)
    echo -e "\n${BOLD}${CYAN}━━━ TEST E2E · ${_LAB_NAME} ━━━${NC}"
}

# Marca única por corrida (anti-frágil)
new_mark() { echo "e2e-$(date +%s)-${RANDOM}"; }

_pass() { _PASS=$((_PASS+1)); echo -e "  ${GREEN}✓${NC} $1"; }
_fail() { _FAIL=$((_FAIL+1)); _FAILURES+=("$1 $2"); echo -e "  ${RED}✗${NC} $1  ${RED}$2${NC}"; }

assert_eq()       { if [ "$1" = "$2" ]; then _pass "$3"; else _fail "$3" "(esperado='$1' actual='$2')"; fi; }
assert_ge()       { if [ "$1" -ge "$2" ] 2>/dev/null; then _pass "$3"; else _fail "$3" "(actual='$1' < min='$2')"; fi; }
assert_contains() { if echo "$1" | grep -qF -- "$2"; then _pass "$3"; else _fail "$3" "(no contiene '$2')"; fi; }
assert_success()  { if [ "$1" -eq 0 ] 2>/dev/null; then _pass "$2"; else _fail "$2" "(exit=$1)"; fi; }

# Aborto temprano (fail-fast): registra el fallo fatal e imprime veredicto FALLIDO ya.
# Uso: abort_test "clúster no subió"  → hace exit 1 (el trap del test hace el teardown).
abort_test() {
    _fail "FATAL" "$1"
    test_end
    exit 1
}

# Veredicto binario + duración. Devuelve 0 si todo PASS, 1 si hubo fallos.
test_end() {
    local dur=$(( $(date +%s) - _T0 ))
    echo ""
    if [ "$_FAIL" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}E2E APROBADO · ${_LAB_NAME} · ${_PASS} aserciones OK · ${dur}s${NC}"
        return 0
    fi
    echo -e "${RED}${BOLD}E2E FALLIDO · ${_LAB_NAME} · ${_FAIL} fallo(s) · ${dur}s:${NC}"
    local f; for f in "${_FAILURES[@]}"; do echo -e "  ${RED}- ${f}${NC}"; done
    return 1
}

# --- Helpers Confluent (Docker Compose) ---

# Espera N brokers healthy (kafka-broker-1..N). Timeout interno propio (sin `timeout` GNU).
wait_for_brokers() {  # <n> [timeout_s]
    local n="${1:-3}" timeout="${2:-150}" waited=0 healthy i
    while [ "$waited" -lt "$timeout" ]; do
        healthy=0
        for i in $(seq 1 "$n"); do
            [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && healthy=$((healthy+1))
        done
        [ "$healthy" -eq "$n" ] && return 0
        sleep 4; waited=$((waited+4))
    done
    return 1
}

# Espera que un contenedor (por nombre) esté healthy o al menos running
wait_for_container() {  # <name> [timeout_s]
    local name="$1" timeout="${2:-120}" waited=0 st
    while [ "$waited" -lt "$timeout" ]; do
        st="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$name" 2>/dev/null)"
        { [ "$st" = "healthy" ] || [ "$st" = "running" ]; } && return 0
        sleep 4; waited=$((waited+4))
    done
    return 1
}

# Produce <count> mensajes "<mark>-1..<count>" (auth opcional)
produce_marked() {  # <container> <bootstrap> <topic> <mark> <count> [config_file]
    local ctr="$1" boot="$2" topic="$3" mark="$4" count="$5" cfg="${6:-}" extra="" i
    [ -n "$cfg" ] && extra="--producer.config $cfg"
    for i in $(seq 1 "$count"); do echo "${mark}-${i}"; done | \
        MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= "$ctr" \
        kafka-console-producer --bootstrap-server "$boot" $extra \
        --command-property acks=all --topic "$topic" 2>/dev/null
}

# Cuenta cuántas de MIS marcas llegaron (ground truth). Imprime el número.
# El grep '^<mark>-' inmuniza contra warnings en stdout.
consume_count_mark() {  # <container> <bootstrap> <topic> <mark> [timeout_ms] [config_file]
    local ctr="$1" boot="$2" topic="$3" mark="$4" tms="${5:-8000}" cfg="${6:-}" extra=""
    [ -n "$cfg" ] && extra="--consumer.config $cfg"
    MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= "$ctr" bash -c \
        "kafka-console-consumer --bootstrap-server $boot $extra --topic $topic --from-beginning --timeout-ms $tms 2>/dev/null | grep -c '^${mark}-'"
}

# Teardown scoped al lab (usa su reset-lab.sh; down -v solo afecta su proyecto compose).
lab_teardown() {  # <lab_dir>
    ( cd "$1" && ( echo "s" | bash bin/reset-lab.sh >/dev/null 2>&1 || \
        docker compose -f infra/docker-compose.yml --env-file infra/.env down -v --remove-orphans >/dev/null 2>&1 ) )
}
