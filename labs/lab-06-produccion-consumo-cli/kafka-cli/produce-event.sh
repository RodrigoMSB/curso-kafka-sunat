#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.fleet.events"
KEY=""
VALUE=""

# Parsear argumentos: --key <key> "<value>"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --key)
            KEY="$2"
            shift 2
            ;;
        --help|-h)
            echo "Uso: $0 [--key <KEY>] \"<MENSAJE>\""
            echo ""
            echo "Ejemplos:"
            echo "  $0 \"vehicle:NVT-1001 status:MOVING\""
            echo "  $0 --key NVT-1001 \"status:STOPPED\""
            exit 0
            ;;
        *)
            VALUE="$1"
            shift
            ;;
    esac
done

if [ -z "$VALUE" ]; then
    echo -e "${YELLOW}[ERROR] Debes proporcionar un mensaje. Usa --help para más info.${NC}"
    exit 1
fi

if [ -n "$KEY" ]; then
    echo -e "${CYAN}[Produce] key='${KEY}' value='${VALUE}'${NC}"
    echo "${KEY}:${VALUE}" | docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC" \
        --property "parse.key=true" \
        --property "key.separator=:"
else
    echo -e "${CYAN}[Produce] value='${VALUE}'${NC}"
    echo "${VALUE}" | docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC"
fi

echo -e "${GREEN}  ✓ Mensaje publicado en ${TOPIC}${NC}"
