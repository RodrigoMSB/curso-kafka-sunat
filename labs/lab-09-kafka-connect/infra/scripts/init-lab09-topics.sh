#!/bin/bash
# Pre-crea el tópico para el Sink connector (el Source crea su propio tópico al arrancar).
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

echo -e "${CYAN}[init-lab09-topics] Creando tópico para Sink connector...${NC}"

create_topic_if_not_exists "novatech.lab09.pedidos.procesados" 3 3

echo -e "${GREEN}✓ Tópico del Lab 09 inicializado${NC}"
echo -e "${YELLOW}  El tópico 'novatech.lab09.pedidos' lo creará el Source connector al arrancar.${NC}"
