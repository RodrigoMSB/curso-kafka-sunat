#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
echo -e "${CYAN}[Brokers registrados en el clúster]${NC}"
docker exec "$BROKER" kafka-broker-api-versions --bootstrap-server "$BOOTSTRAP" 2>/dev/null \
    | grep -oE '^[a-z0-9.-]+:[0-9]+' | sort -u
echo ""
echo -e "${CYAN}[Metadata del clúster]${NC}"
docker exec "$BROKER" kafka-metadata-quorum --bootstrap-server "$BOOTSTRAP" describe --status 2>/dev/null || true
