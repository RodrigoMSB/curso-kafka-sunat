#!/bin/bash
# Produce un FLOOD continuo a novatech.lab08.transactions para que
# Control Center muestre throughput real y métricas en sus dashboards.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

DURATION="${1:-300}"  # default 5 minutos
RATE="${2:-100}"      # default 100 msg/seg
TOPIC="novatech.lab08.transactions"

echo -e "${CYAN}[Produce Flood Lab 08] -> ${TOPIC}${NC}"
echo "  Duración: ${DURATION}s"
echo "  Rate:     ${RATE} msg/seg"
echo "  Tip: deja esto corriendo y abre Control Center en otra ventana"
echo "────────────────────────────────────────────────────────"

# kafka-producer-perf-test con throughput limitado
docker exec "$BROKER" kafka-producer-perf-test \
    --topic "$TOPIC" \
    --num-records $((RATE * DURATION)) \
    --record-size 200 \
    --throughput "$RATE" \
    --producer-props \
        bootstrap.servers="$BOOTSTRAP" \
        acks=all \
        compression.type=lz4
