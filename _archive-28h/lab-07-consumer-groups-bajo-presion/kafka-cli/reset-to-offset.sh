#!/bin/bash
# Resetea el offset de un grupo a un offset específico en una partición.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 3 ]; then
    cat <<EOF
Uso: $0 <GROUP> <PARTITION> <OFFSET>

Resetea el offset del grupo en una PARTICIÓN específica al OFFSET dado.
El grupo NO debe tener consumers activos.

Ejemplos:
  $0 alertas 0 100        # En partición 0, offset 100
  $0 reportes 5 0         # En partición 5, vuelve al inicio
EOF
    exit 1
fi

GROUP="$1"
PARTITION="$2"
OFFSET="$3"
TOPIC="novatech.lab07.eventos"

echo -e "${YELLOW}[Reset to Offset] grupo=${GROUP} ${TOPIC}:${PARTITION} -> ${OFFSET}${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --reset-offsets \
    --group "$GROUP" \
    --topic "${TOPIC}:${PARTITION}" \
    --to-offset "$OFFSET" \
    --execute
