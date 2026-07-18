#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
if [ $# -lt 2 ]; then
    echo "Uso: $0 <broker-id|default> <clave=valor>"
    echo "Ejemplo: $0 1 log.cleaner.threads=2"
    echo "Ejemplo (cluster-wide): $0 default log.retention.ms=3600000"
    exit 1
fi
ENTITY="$1"; CONFIG="$2"
echo -e "${YELLOW}[Alter] broker=${ENTITY} ${CONFIG}${NC}"
if [ "$ENTITY" = "default" ]; then
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --alter --entity-type brokers --entity-default --add-config "$CONFIG"
else
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --alter --entity-type brokers --entity-name "$ENTITY" --add-config "$CONFIG"
fi
echo -e "${GREEN}✓ Configuración aplicada en caliente (sin reinicio)${NC}"
