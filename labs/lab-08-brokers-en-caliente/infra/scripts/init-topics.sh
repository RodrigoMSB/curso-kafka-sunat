#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-kafka-broker-1:29092}"
TOPIC_NAME="${TOPIC_NAME:-novatech.lab08.pedidos}"
PARTITIONS="${PARTITIONS:-6}"
REPLICATION_FACTOR="${REPLICATION_FACTOR:-3}"

echo -e "${YELLOW}[NovaTech] Esperando al clúster...${NC}"
MAX_RETRIES=30; RETRY_COUNT=0
while ! kafka-broker-api-versions --bootstrap-server "$BOOTSTRAP_SERVER" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo -e "${RED}[ERROR] Timeout esperando al clúster${NC}"; exit 1
    fi
    sleep 5
done
echo -e "${GREEN}[OK] Clúster disponible${NC}"

if kafka-topics --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -q "^${TOPIC_NAME}$"; then
    echo -e "${YELLOW}[INFO] El tópico '${TOPIC_NAME}' ya existe.${NC}"
else
    kafka-topics --bootstrap-server "$BOOTSTRAP_SERVER" --create \
        --topic "$TOPIC_NAME" --partitions "$PARTITIONS" --replication-factor "$REPLICATION_FACTOR"
    echo -e "${GREEN}✓ Tópico '${TOPIC_NAME}' creado (${PARTITIONS} particiones, RF ${REPLICATION_FACTOR})${NC}"
fi
