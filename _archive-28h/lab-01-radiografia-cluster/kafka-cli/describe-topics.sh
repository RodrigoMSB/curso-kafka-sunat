#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - CLI: Describir tópico GPS
# ============================================================

# shellcheck source=../bin/common.sh
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[NovaTech CLI] Descripción del tópico novatech.fleet.gps${NC}"
echo -e "${CYAN}  (vía ${BROKER})${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --describe \
    --topic novatech.fleet.gps
echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}[OK] Comando ejecutado${NC}"
