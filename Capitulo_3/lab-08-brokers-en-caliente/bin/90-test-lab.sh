#!/bin/bash
# ============================================================
# Lab 08 - Validador del alumno (90)
# Verifica el estado ACTUAL de tu laboratorio (3 brokers base).
# El broker-4 NO es parte del estado esperado al inicio.
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
BOOT="kafka-broker-1:29092"
TOPIC="novatech.lab08.pedidos"

echo -e "${BOLD}Validador del Lab 08 — estado actual${NC}"

# 1. Brokers base (3)
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers base están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. Tópico del lab
if [ "$VIVOS" -gt 0 ] && docker exec kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" --list 2>/dev/null | grep -q "^${TOPIC}$"; then
    ok "el tópico ${TOPIC} existe"
else
    bad "el tópico ${TOPIC} no existe" "ejecuta bin/start-lab.sh (crea el tópico del lab)"
fi

# 3. Config del broker legible (con --all para no depender de que exista un override dinámico)
if [ "$VIVOS" -eq 3 ]; then
    CFG=$(docker exec kafka-broker-1 kafka-configs --bootstrap-server "$BOOT" \
        --describe --entity-type brokers --entity-name 1 --all 2>/dev/null)
    if echo "$CFG" | grep -q 'num.replica.fetchers'; then ok "config del broker 1 legible (describe-broker-config)"
    else bad "no pude leer la config del broker 1" "revisa que el clúster responda: kafka-cli/describe-broker-config.sh 1"; fi
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
