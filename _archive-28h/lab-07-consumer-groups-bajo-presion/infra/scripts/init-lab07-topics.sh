#!/bin/bash
# Crea los 2 tópicos del Lab 07 de manera idempotente.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/../../bin" && pwd)"
source "${SCRIPT_DIR}/common.sh"
resolve_broker

create_topic_if_not_exists() {
    local TOPIC="$1"
    local PARTITIONS="$2"
    local RF="$3"
    shift 3
    local CONFIGS=("$@")

    local EXISTS
    EXISTS=$(docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" --list 2>/dev/null | grep -c "^${TOPIC}$" || true)

    if [ "$EXISTS" -eq 1 ]; then
        echo -e "${YELLOW}  El tópico ${TOPIC} ya existe. No se recrea.${NC}"
        return
    fi

    local CONFIG_ARGS=()
    for cfg in "${CONFIGS[@]}"; do
        CONFIG_ARGS+=("--config" "$cfg")
    done

    docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
        --create \
        --topic "$TOPIC" \
        --partitions "$PARTITIONS" \
        --replication-factor "$RF" \
        "${CONFIG_ARGS[@]}"

    echo -e "${GREEN}  ✓ Tópico ${TOPIC} creado (${PARTITIONS} particiones, RF=${RF})${NC}"
}

echo -e "${CYAN}[init-lab07-topics] Creando tópicos del Lab 07...${NC}"

create_topic_if_not_exists "novatech.lab07.eventos" 12 3 \
    "min.insync.replicas=2"

create_topic_if_not_exists "novatech.lab07.dlq" 3 3 \
    "min.insync.replicas=2"

echo -e "${GREEN}✓ Tópicos del Lab 07 inicializados${NC}"
