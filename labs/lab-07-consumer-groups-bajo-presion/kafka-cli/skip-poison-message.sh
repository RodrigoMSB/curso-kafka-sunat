#!/bin/bash
# Avanza el offset de un grupo en 1 unidad para "saltar" un mensaje problemático.
# Útil cuando un mensaje hace crashear al consumer y queremos continuar.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 2 ]; then
    cat <<EOF
Uso: $0 <GROUP> <PARTITION>

Avanza el offset del grupo en la partición especificada en +1.
El grupo NO debe tener consumers activos.

Útil cuando un mensaje "venenoso" está bloqueando el consumo y necesitas
saltarlo para que el grupo siga procesando los siguientes.

Ejemplo:
  $0 alertas 3
EOF
    exit 1
fi

GROUP="$1"
PARTITION="$2"
TOPIC="novatech.lab07.eventos"

# Obtener offset actual
CURRENT_OFFSET=$(docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --describe \
    --group "$GROUP" 2>/dev/null | awk -v t="$TOPIC" -v p="$PARTITION" \
    '$2 == t && $3 == p { print $4 }')

if [ -z "$CURRENT_OFFSET" ] || [ "$CURRENT_OFFSET" = "-" ]; then
    echo -e "${RED}[ERROR] No se pudo determinar el offset actual.${NC}"
    echo -e "${YELLOW}  Verifica que el grupo '${GROUP}' existe y consumió de la partición ${PARTITION}.${NC}"
    exit 1
fi

NEW_OFFSET=$((CURRENT_OFFSET + 1))

echo -e "${YELLOW}[Skip Poison Message] grupo=${GROUP} partición=${PARTITION}${NC}"
echo "  Offset actual: ${CURRENT_OFFSET}"
echo "  Saltar a:      ${NEW_OFFSET}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --reset-offsets \
    --group "$GROUP" \
    --topic "${TOPIC}:${PARTITION}" \
    --to-offset "$NEW_OFFSET" \
    --execute

echo -e "${GREEN}  ✓ Mensaje en offset ${CURRENT_OFFSET} saltado.${NC}"
echo -e "${YELLOW}  IMPORTANTE: en producción real, consideraría enviarlo a una DLQ${NC}"
echo -e "${YELLOW}  antes de saltarlo, para no perder evidencia del problema.${NC}"
