#!/bin/bash
# Lista todos los tópicos del clúster.
# Por defecto excluye tópicos internos (ej: __consumer_offsets).
# Usar --internal para verlos también.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

echo -e "${CYAN}[List Topics]${NC}"
echo "────────────────────────────────────────────────────────"

if [ "${1:-}" = "--internal" ]; then
    echo -e "${YELLOW}(incluyendo tópicos internos)${NC}"
    docker exec "$BROKER" kafka-topics \
        --bootstrap-server "$BOOTSTRAP" \
        --list
else
    docker exec "$BROKER" kafka-topics \
        --bootstrap-server "$BOOTSTRAP" \
        --list \
        --exclude-internal
fi
