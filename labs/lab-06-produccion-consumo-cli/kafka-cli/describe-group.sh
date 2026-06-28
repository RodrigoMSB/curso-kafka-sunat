#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_GRUPO>"
    echo "Ejemplo: $0 alertas"
    exit 1
fi

GROUP="$1"

echo -e "${CYAN}[Describe Group] grupo=${GROUP}${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --describe \
    --group "$GROUP"
