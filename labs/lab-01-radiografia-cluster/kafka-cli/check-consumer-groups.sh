#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - CLI: Grupos de consumidores
# ============================================================

# shellcheck source=../bin/common.sh
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[NovaTech CLI] Grupos de consumidores${NC}"
echo -e "${CYAN}  (vía ${BROKER})${NC}"
echo "────────────────────────────────────────────────────────"

GROUPS=$(docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --list 2>/dev/null || true)

if [ -z "$GROUPS" ]; then
    echo -e "${YELLOW}  No hay grupos de consumidores activos.${NC}"
    echo -e "${YELLOW}  Ejecuta consume-gps.sh primero para crear un grupo.${NC}"
else
    echo -e "${CYAN}  Grupos encontrados:${NC}"
    echo "$GROUPS"
    echo ""
    echo -e "${CYAN}  Detalle de todos los grupos:${NC}"
    echo "────────────────────────────────────────────────────────"
    docker exec "$BROKER" kafka-consumer-groups \
        --bootstrap-server "$BOOTSTRAP" \
        --describe --all-groups
fi

echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}[OK] Comando ejecutado${NC}"
