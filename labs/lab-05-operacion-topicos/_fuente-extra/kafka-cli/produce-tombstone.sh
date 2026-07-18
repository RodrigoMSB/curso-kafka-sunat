#!/bin/bash
# Produce un mensaje con valor NULL (tombstone) para un tópico compactado.
# Esto marca la clave para eliminación lógica en la próxima compactación.
#
# Mecánica: kafka-console-producer interpreta cualquier valor que coincida con
# el "null.marker" como un mensaje con value=null (tombstone real).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <CLAVE>

Produce un tombstone (mensaje con valor null) para la clave dada.
Solo tiene sentido en tópicos con cleanup.policy=compact.

Ejemplo:
  $0 novatech.lab05.estado NVT-1001
EOF
    exit 1
fi

TOPIC="$1"
KEY="$2"

echo -e "${CYAN}[Produce Tombstone] tópico=${TOPIC} clave=${KEY}${NC}"

# Enviar UN solo mensaje cuyo valor coincide con null.marker.
# kafka-console-producer lo traducirá a un value=null real.
echo "${KEY}:__NULL__" | docker exec -i "$BROKER" kafka-console-producer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC" \
    --property "parse.key=true" \
    --property "key.separator=:" \
    --property "null.marker=__NULL__"

echo -e "${GREEN}  ✓ Tombstone enviado (1 mensaje con value=null)${NC}"
echo -e "${YELLOW}  Tras la próxima compactación, los mensajes anteriores con${NC}"
echo -e "${YELLOW}  clave='${KEY}' serán eliminados. El tombstone permanece${NC}"
echo -e "${YELLOW}  visible durante 'delete.retention.ms' (default: 24h).${NC}"
