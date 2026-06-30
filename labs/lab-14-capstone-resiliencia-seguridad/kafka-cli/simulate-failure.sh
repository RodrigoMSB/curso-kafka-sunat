#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
BROKER_NUM="${1:-3}"
echo -e "${YELLOW}[Failover] Deteniendo kafka-broker-${BROKER_NUM} (simulación de fallo de nodo)...${NC}"
docker stop "kafka-broker-${BROKER_NUM}"
echo -e "${RED}  ✗ kafka-broker-${BROKER_NUM} caído.${NC}"
echo -e "${CYAN}  Observa el nuevo liderazgo:  kafka-cli/describe-confidencial.sh${NC}"
echo -e "${CYAN}  Recupéralo cuando quieras:    kafka-cli/recover-broker.sh ${BROKER_NUM}${NC}"
