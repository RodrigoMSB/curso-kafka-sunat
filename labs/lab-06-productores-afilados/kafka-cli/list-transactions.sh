#!/bin/bash
# Lista todas las transacciones activas en el clúster.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[List Transactions]${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-transactions \
    --bootstrap-server "$BOOTSTRAP" \
    list
