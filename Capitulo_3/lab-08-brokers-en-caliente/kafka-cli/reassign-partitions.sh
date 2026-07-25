#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
BROKER_LIST="${2:-1,2,3,4}"

echo -e "${CYAN}[Reasignación] ${TOPIC} → brokers ${BROKER_LIST}${NC}"

echo "{\"topics\":[{\"topic\":\"${TOPIC}\"}],\"version\":1}" > /tmp/lab08-topics-to-move.json
docker cp /tmp/lab08-topics-to-move.json "${BROKER}:/tmp/topics-to-move.json"

echo -e "${YELLOW}Generando plan...${NC}"
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --topics-to-move-json-file /tmp/topics-to-move.json --broker-list "$BROKER_LIST" --generate \
    > /tmp/lab08-reassign-output.txt
sed -n '/Proposed partition reassignment configuration/,$p' /tmp/lab08-reassign-output.txt \
    | tail -n +2 | head -n 1 > /tmp/lab08-reassignment.json
docker cp /tmp/lab08-reassignment.json "${BROKER}:/tmp/reassignment.json"
echo -e "${YELLOW}Plan propuesto:${NC}"; cat /tmp/lab08-reassignment.json; echo ""

echo -e "${YELLOW}Ejecutando...${NC}"
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --reassignment-json-file /tmp/reassignment.json --execute

echo -e "${YELLOW}Verificando (espera unos segundos)...${NC}"; sleep 5
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --reassignment-json-file /tmp/reassignment.json --verify || true
echo -e "${GREEN}✓ Reasignación lanzada${NC}"
