#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - CLI: Estado del quorum KRaft
# ============================================================

# shellcheck source=../bin/common.sh
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[NovaTech CLI] Estado del quorum KRaft${NC}"
echo -e "${CYAN}  (vía ${BROKER})${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-metadata-quorum \
    --bootstrap-server "$BOOTSTRAP" \
    describe --status
echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}[OK] Comando ejecutado${NC}"
