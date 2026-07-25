#!/bin/bash
# ============================================================
# Lab 10 - Validador del alumno (90)
# Verifica el estado ACTUAL: brokers + REST Proxy + kafbat UI.
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
REST_PORT="${REST_PROXY_PORT:-8082}"
UI_PORT="${KAFBAT_UI_PORT:-8090}"
TOPIC="novatech.lab10.pedidos"

echo -e "${BOLD}Validador del Lab 10 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. REST Proxy responde /topics y ve el tópico del lab
if TOPICS=$(curl -sf "http://localhost:${REST_PORT}/topics" 2>/dev/null); then
    ok "REST Proxy responde en :${REST_PORT}/topics"
    if echo "$TOPICS" | grep -q "$TOPIC"; then ok "el tópico ${TOPIC} es visible vía REST"
    else bad "el tópico ${TOPIC} no aparece vía REST" "ejecuta bin/start-lab.sh (crea y siembra el tópico)"; fi
else
    bad "REST Proxy no responde en :${REST_PORT}" "revisa el contenedor kafka-rest: docker logs kafka-rest"
fi

# 3. kafbat UI arriba
if curl -sf "http://localhost:${UI_PORT}/actuator/health" 2>/dev/null | grep -qi 'up'; then
    ok "kafbat UI responde UP en :${UI_PORT}"
else
    bad "kafbat UI no responde en :${UI_PORT}" "espera unos segundos o revisa docker logs kafbat-ui"
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
