#!/bin/bash
# Elimina un tópico (con confirmación interactiva).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_TOPICO>"
    exit 1
fi

TOPIC="$1"

echo -e "${RED}⚠  Vas a ELIMINAR el tópico '${TOPIC}' y TODOS sus mensajes.${NC}"
echo -n "Escribe el nombre del tópico para confirmar: "
read CONFIRM

if [ "$CONFIRM" != "$TOPIC" ]; then
    echo -e "${YELLOW}Cancelado.${NC}"
    exit 0
fi

docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --delete \
    --topic "$TOPIC"

echo -e "${GREEN}  ✓ Tópico ${TOPIC} eliminado${NC}"
