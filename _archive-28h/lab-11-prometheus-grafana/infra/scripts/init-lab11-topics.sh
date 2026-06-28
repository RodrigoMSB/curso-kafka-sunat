#!/bin/bash
# Pre-crea el tópico del Lab 11 para experimentos de carga.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../../bin" && pwd)"
source "${SCRIPT_DIR}/common.sh"
resolve_broker

create_topic_if_not_exists() {
    local TOPIC="$1"
    local PARTITIONS="$2"
    local RF="$3"

    local EXISTS
    EXISTS=$(docker exec -e KAFKA_OPTS= "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" --list 2>/dev/null | grep -c "^${TOPIC}$" || true)

    if [ "$EXISTS" -eq 1 ]; then
        echo -e "${YELLOW}  El tópico ${TOPIC} ya existe.${NC}"
        return
    fi

    docker exec -e KAFKA_OPTS= "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
        --create \
        --topic "$TOPIC" \
        --partitions "$PARTITIONS" \
        --replication-factor "$RF"

    echo -e "${GREEN}  ✓ Tópico ${TOPIC} creado (${PARTITIONS} particiones, RF=${RF})${NC}"
}

echo -e "${CYAN}[init-lab11-topics] Creando tópico del Lab 11...${NC}"

create_topic_if_not_exists "novatech.lab11.eventos" 12 3

echo -e "${GREEN}✓ Tópico del Lab 11 inicializado${NC}"
