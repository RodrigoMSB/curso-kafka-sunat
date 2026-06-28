#!/bin/bash
# Produce un flood continuo a novatech.lab11.eventos para que
# Grafana muestre throughput real y métricas en sus paneles.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

DURATION="${1:-300}"  # default 5 minutos
RATE="${2:-100}"      # default 100 msg/seg
TOPIC="novatech.lab11.eventos"

echo -e "${CYAN}[Produce Flood Lab 11] -> ${TOPIC}${NC}"
echo "  Duración: ${DURATION}s"
echo "  Rate:     ${RATE} msg/seg"
echo "  Tip: deja esto corriendo y abre Grafana en otra ventana"
echo "────────────────────────────────────────────────────────"

docker exec -e KAFKA_OPTS= "$BROKER" kafka-producer-perf-test \
    --topic "$TOPIC" \
    --num-records $((RATE * DURATION)) \
    --record-size 200 \
    --throughput "$RATE" \
    --producer-props \
        bootstrap.servers="$BOOTSTRAP" \
        acks=all \
        compression.type=lz4
