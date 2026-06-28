#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - CLI: Estado de replicación del clúster
# ============================================================

# shellcheck source=../bin/common.sh
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[NovaTech CLI] Estado de replicación del clúster${NC}"
echo -e "${CYAN}  (vía ${BROKER})${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-metadata-quorum \
    --bootstrap-server "$BOOTSTRAP" \
    describe --replication
echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}[OK] Comando ejecutado${NC}"
