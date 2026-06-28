#!/bin/bash
# Monitorea el lag de un consumer group cada N segundos.
# Útil para ver lag crecer/decrecer en tiempo real.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <GROUP> [INTERVAL_SEG]

Monitorea el lag de un consumer group cada INTERVAL segundos (default: 2).
Presiona Ctrl+C para detener.

Ejemplos:
  $0 alertas
  $0 alertas 1
EOF
    exit 1
fi

GROUP="$1"
INTERVAL="${2:-2}"

echo -e "${CYAN}[Monitor Lag] grupo=${GROUP} (cada ${INTERVAL}s)${NC}"
echo -e "${YELLOW}Presiona Ctrl+C para detener${NC}"
echo "════════════════════════════════════════════════════════"

trap "echo ''; echo -e '${YELLOW}Monitor detenido.${NC}'; exit 0" INT

while true; do
    echo -e "${CYAN}─── $(date '+%H:%M:%S') ───${NC}"
    docker exec "$BROKER" kafka-consumer-groups \
        --bootstrap-server "$BOOTSTRAP" \
        --describe \
        --group "$GROUP" 2>/dev/null | grep -E "^GROUP|^${GROUP}" | head -15

    # Calcular lag total
    LAG_TOTAL=$(docker exec "$BROKER" kafka-consumer-groups \
        --bootstrap-server "$BOOTSTRAP" \
        --describe \
        --group "$GROUP" 2>/dev/null | awk 'NR>1 && $6 != "-" { sum += $6 } END { print sum+0 }')

    echo -e "${YELLOW}LAG TOTAL: ${LAG_TOTAL}${NC}"
    echo ""
    sleep "$INTERVAL"
done
