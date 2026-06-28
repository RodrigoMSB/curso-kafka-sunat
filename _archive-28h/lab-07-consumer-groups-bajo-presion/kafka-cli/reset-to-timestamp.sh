#!/bin/bash
# Resetea el offset de un grupo a un timestamp específico.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 2 ]; then
    cat <<EOF
Uso: $0 <GROUP> <TIMESTAMP_ISO>

TIMESTAMP_ISO en formato yyyy-MM-ddTHH:mm:ss.sssXXX (ISO 8601).

El grupo NO debe tener consumers activos.

Ejemplos:
  $0 alertas 2026-04-26T15:00:00.000-04:00
  $0 alertas 2026-04-26T00:00:00.000Z
EOF
    exit 1
fi

GROUP="$1"
TIMESTAMP="$2"
TOPIC="novatech.lab07.eventos"

echo -e "${YELLOW}[Reset to Timestamp] grupo=${GROUP} -> ${TIMESTAMP}${NC}"
echo -e "${YELLOW}  Asegúrate de que el grupo no tenga consumers activos.${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --reset-offsets \
    --group "$GROUP" \
    --topic "$TOPIC" \
    --to-datetime "$TIMESTAMP" \
    --execute
