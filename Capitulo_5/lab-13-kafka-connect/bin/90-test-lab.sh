#!/bin/bash
# ============================================================
# Lab 13 - Validador del alumno (90)
# Verifica el estado ACTUAL: brokers + Kafka Connect. Si el connector
# del lab existe, reporta su estado.
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }
info(){ echo -e "  ${CYAN}·${NC} $1"; }

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
CONNECT="http://localhost:8083"
CONN="novatech-source-pedidos"

echo -e "${BOLD}Validador del Lab 13 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. Kafka Connect responde
if LISTA=$(curl -sf --max-time 8 "${CONNECT}/connectors" 2>/dev/null); then
    ok "Kafka Connect responde en :8083/connectors"
    # 3. Estado del connector (informativo)
    if echo "$LISTA" | grep -q "$CONN"; then
        ST=$(curl -sf --max-time 8 "${CONNECT}/connectors/${CONN}/status" 2>/dev/null | grep -o '"state":"[A-Z]*"' | head -1)
        ok "el connector ${CONN} existe (${ST:-estado desconocido})"
    else
        info "aún no creas el connector. Prueba: connect-cli/create-source.sh"
    fi
else
    bad "Kafka Connect no responde en :8083" "puede tardar en arrancar; revisa docker logs kafka-connect"
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
