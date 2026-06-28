#!/bin/bash
# Muestra la descripción completa de un tópico:
# - Particiones, líderes, ISR
# - Configuraciones efectivas (heredadas + overrides)

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_TOPICO>"
    exit 1
fi

TOPIC="$1"

echo -e "${CYAN}[Describe Topic] ${TOPIC}${NC}"
echo "════════════════════════════════════════════════════════"

echo -e "${YELLOW}── Particiones, líderes y réplicas ──${NC}"
docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --describe \
    --topic "$TOPIC"

echo ""
echo -e "${YELLOW}── Configuraciones efectivas (overrides + dynamic + default) ──${NC}"
docker exec "$BROKER" kafka-configs \
    --bootstrap-server "$BOOTSTRAP" \
    --entity-type topics \
    --entity-name "$TOPIC" \
    --describe \
    --all 2>/dev/null | head -50
