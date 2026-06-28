#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[Consumer Groups] del clúster${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" --list
