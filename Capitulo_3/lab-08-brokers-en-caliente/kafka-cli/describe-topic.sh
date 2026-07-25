#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
echo -e "${CYAN}[Describe] ${TOPIC}${NC}"
docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" --describe --topic "$TOPIC"
