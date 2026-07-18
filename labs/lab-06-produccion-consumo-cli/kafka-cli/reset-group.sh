#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.fleet.events"

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_GRUPO>"
    echo ""
    echo "Resetea los offsets del grupo al inicio (offset 0 en todas las particiones)."
    echo "El grupo NO debe tener consumidores activos al ejecutar este comando."
    exit 1
fi

GROUP="$1"

echo -e "${YELLOW}[Reset Group] grupo=${GROUP} -> --to-earliest${NC}"
echo -e "${YELLOW}  Asegúrate de que no haya consumidores activos en este grupo.${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --reset-offsets \
    --group "$GROUP" \
    --topic "$TOPIC" \
    --to-earliest \
    --execute
