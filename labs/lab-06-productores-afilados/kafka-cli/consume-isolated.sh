#!/bin/bash
# Consume mensajes con isolation level configurable.
# read_uncommitted (default): ve TODOS los mensajes incluso de transacciones abortadas
# read_committed: ve SOLO mensajes de transacciones commiteadas

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <TOPICO> [ISOLATION_LEVEL] [--max N]

ISOLATION_LEVEL: read_uncommitted (default) | read_committed

Ejemplos:
  $0 novatech.payments.confirmed read_committed
  $0 novatech.payments.confirmed read_uncommitted --max 50
EOF
    exit 1
fi

TOPIC="$1"
ISOLATION="${2:-read_uncommitted}"
MAX_MESSAGES=20

# Si el segundo arg empieza con --, no era isolation
if [[ "${2:-}" == --* ]]; then
    ISOLATION="read_uncommitted"
    shift 1
else
    shift 2 2>/dev/null || shift 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max) MAX_MESSAGES="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

if [ "$ISOLATION" != "read_committed" ] && [ "$ISOLATION" != "read_uncommitted" ]; then
    echo -e "${RED}[ERROR] ISOLATION_LEVEL debe ser 'read_committed' o 'read_uncommitted'${NC}"
    exit 1
fi

echo -e "${CYAN}[Consume Isolated] ${TOPIC}${NC}"
echo "  Isolation level: ${ISOLATION}"
echo "  Max mensajes:    ${MAX_MESSAGES}"
echo "────────────────────────────────────────────────────────"

docker exec -i "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC" \
    --from-beginning \
    --max-messages "$MAX_MESSAGES" \
    --isolation-level "$ISOLATION" \
    --property "print.key=true" \
    --property "key.separator= -> " \
    --timeout-ms 10000 || true
