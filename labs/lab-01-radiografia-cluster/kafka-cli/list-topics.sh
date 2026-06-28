#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - CLI: Listar tópicos
# ============================================================

# shellcheck source=../bin/common.sh
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[NovaTech CLI] Tópicos del clúster${NC}"
echo -e "${CYAN}  (vía ${BROKER})${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --list
echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}[OK] Comando ejecutado${NC}"
