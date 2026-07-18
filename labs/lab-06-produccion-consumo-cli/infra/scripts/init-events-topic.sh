#!/bin/bash
set -euo pipefail

# Carga common.sh para resolver broker vivo y colores
SCRIPT_DIR="$(cd "$(dirname "$0")/../../bin" && pwd)"
source "${SCRIPT_DIR}/common.sh"
resolve_broker

TOPIC_NAME="novatech.fleet.events"
PARTITIONS=6
REPLICATION_FACTOR=3

echo -e "${CYAN}[init-events-topic] Verificando tópico ${TOPIC_NAME}...${NC}"

# Verificar si el tópico ya existe
EXISTS=$(docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" --list 2>/dev/null | grep -c "^${TOPIC_NAME}$" || true)

if [ "$EXISTS" -eq 1 ]; then
    echo -e "${YELLOW}  El tópico ${TOPIC_NAME} ya existe. No se recrea.${NC}"
else
    docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
        --create \
        --topic "$TOPIC_NAME" \
        --partitions "$PARTITIONS" \
        --replication-factor "$REPLICATION_FACTOR"
    echo -e "${GREEN}  ✓ Tópico ${TOPIC_NAME} creado (${PARTITIONS} particiones, RF=${REPLICATION_FACTOR})${NC}"
fi
