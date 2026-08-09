#!/bin/bash
# E2E instructor · Lab 10 - REST Proxy
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 10)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-10-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 10"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 10 - REST Proxy"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh rest-cli/*.sh infra/scripts/*.sh 2>/dev/null

REST_PORT="${REST_PROXY_PORT:-8082}"
TOPIC="novatech.lab10.pedidos"

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
wait_for_container kafka-rest 120 || abort_test "REST Proxy no llegó a healthy"
_pass "clúster + REST Proxy arriba"

# 1. GET /topics ve el tópico del lab
TOPICS=$(curl -sf "http://localhost:${REST_PORT}/topics" 2>/dev/null || true)
assert_contains "$TOPICS" "$TOPIC" "REST GET /topics lista ${TOPIC}"

# 2. Producir vía HTTP con marca única en el JSON → la respuesta trae offset
MARK="$(new_mark)"
PRESP=$(bash rest-cli/rest-produce.sh "$TOPIC" "{\"pedido\":999,\"cliente\":\"${MARK}\",\"monto\":1}" 2>&1 || true)
assert_contains "$PRESP" "offset" "rest-produce devuelve offset (mensaje aceptado)"

# 3. Consumir vía HTTP (grupo único → earliest) → aparece mi marca
CRESP=$(bash rest-cli/rest-consume.sh "$TOPIC" "e2e-grp-${MARK}" 2>&1 || true)
assert_contains "$CRESP" "$MARK" "rest-consume devuelve mi marca ($MARK)"

# El 90 del alumno también debe aprobar sobre el lab vivo
# La salida del validador del alumno NO se tira: si el 90 aprueba diciendo
# algo falso, o falla, el e2e tiene que mostrarlo. Era el ultimo vector de
# verde con material roto (SPEC-66 F1).
SALIDA_90=$(bash bin/90-test-lab.sh 2>&1); RC90=$?
printf '%s\n' "$SALIDA_90"
assert_success "$RC90" "el validador del alumno (90) aprueba sobre el lab vivo"
assert_contains "$SALIDA_90" "LAB EN BUEN ESTADO" "el 90 imprime su linea de conteo (se lee, no se asume)"

test_end; exit $?
