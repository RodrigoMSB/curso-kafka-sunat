#!/bin/bash
# Pre-crea los tópicos del Lab 10 (pedidos y clientes).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../../bin" && pwd)"
source "${SCRIPT_DIR}/common.sh"
resolve_broker

create_topic_if_not_exists() {
    local TOPIC="$1"
    local PARTITIONS="$2"
    local RF="$3"

    local EXISTS
    EXISTS=$(docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" --list 2>/dev/null | grep -c "^${TOPIC}$" || true)

    if [ "$EXISTS" -eq 1 ]; then
        echo -e "${YELLOW}  El tópico ${TOPIC} ya existe.${NC}"
        return
    fi

    docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
        --create \
        --topic "$TOPIC" \
        --partitions "$PARTITIONS" \
        --replication-factor "$RF"

    echo -e "${GREEN}  ✓ Tópico ${TOPIC} creado (${PARTITIONS} particiones, RF=${RF})${NC}"
}

echo -e "${CYAN}[init-lab10-topics] Creando tópicos del Lab 10...${NC}"

create_topic_if_not_exists "novatech.lab10.pedidos" 12 3
create_topic_if_not_exists "novatech.lab10.clientes" 3 3

echo -e "${GREEN}✓ Tópicos del Lab 10 inicializados${NC}"
