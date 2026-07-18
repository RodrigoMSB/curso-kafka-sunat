#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
REMAINING="${2:-1,2,3}"   # brokers que SE QUEDAN (sin el que se drena)
echo -e "${CYAN}[Drenar] Moviendo ${TOPIC} a brokers ${REMAINING} (excluye el resto)${NC}"
"$(dirname "$0")/reassign-partitions.sh" "$TOPIC" "$REMAINING"
echo -e "${GREEN}✓ Particiones drenadas. El broker excluido ya puede detenerse:${NC}"
echo -e "${CYAN}  docker compose -f infra/docker-compose.yml --profile scale stop kafka-broker-4${NC}"
