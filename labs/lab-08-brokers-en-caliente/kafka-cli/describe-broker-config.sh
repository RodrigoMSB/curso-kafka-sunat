#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
ENTITY="${1:-1}"   # id de broker, o "default"
echo -e "${CYAN}[Config broker ${ENTITY}]${NC}"
if [ "$ENTITY" = "default" ]; then
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --describe --entity-type brokers --entity-default
else
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --describe --entity-type brokers --entity-name "$ENTITY"
fi
