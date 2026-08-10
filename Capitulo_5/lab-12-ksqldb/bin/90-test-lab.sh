#!/bin/bash
# ============================================================
# Lab 12 - Validador del alumno (90)
# Verifica el estado ACTUAL: brokers + ksqlDB server + SHOW STREAMS.
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
KSQL="http://localhost:8088"

ficha_op_verifica 'QUÉ VA A VERIFICAR' \
    'los 3 brokers están healthy' \
    'el servidor ksqlDB responde /info' \
    'SHOW STREAMS responde' \

echo -e "${BOLD}Validador del Lab 12 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. ksqlDB server responde
if curl -sf --max-time 8 "${KSQL}/info" >/dev/null 2>&1; then
    ok "ksqlDB server responde en :8088"
    # 3. SHOW STREAMS responde
    RESP=$(curl -sf --max-time 10 -X POST "${KSQL}/ksql" \
        -H 'Content-Type: application/vnd.ksql.v1+json' \
        -d '{"ksql":"SHOW STREAMS;"}' 2>/dev/null || true)
    if echo "$RESP" | grep -q 'streams'; then ok "SHOW STREAMS responde"
    else bad "SHOW STREAMS no respondió" "espera a que ksqlDB termine de iniciar (puede tardar 60-90s)"; fi
else
    bad "ksqlDB server no responde en :8088" "puede tardar 60-90s en arrancar; revisa docker logs ksqldb-server"
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
