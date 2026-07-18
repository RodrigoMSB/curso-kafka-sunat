#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
NUM="${2:-5000}"
echo -e "${CYAN}[Sample] Produciendo ${NUM} mensajes en ${TOPIC}...${NC}"
docker exec "$BROKER" kafka-producer-perf-test \
    --topic "$TOPIC" --num-records "$NUM" --record-size 256 --throughput -1 \
    --producer-props bootstrap.servers="$BOOTSTRAP"
echo -e "${GREEN}✓ Mensajes producidos${NC}"
