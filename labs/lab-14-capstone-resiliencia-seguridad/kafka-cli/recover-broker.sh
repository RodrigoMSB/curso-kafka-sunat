#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
BROKER_NUM="${1:-3}"
echo -e "${YELLOW}[Recuperación] Levantando kafka-broker-${BROKER_NUM}...${NC}"
docker start "kafka-broker-${BROKER_NUM}"
echo -e "${GREEN}  ✓ kafka-broker-${BROKER_NUM} de vuelta. El ISR debería volver a 3 en unos segundos.${NC}"
