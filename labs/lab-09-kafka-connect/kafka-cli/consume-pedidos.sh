#!/bin/bash
# Consume mensajes del tópico novatech.lab09.pedidos
# (creado automáticamente por el JDBC Source connector).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.lab09.pedidos"

echo -e "${CYAN}[Consume Pedidos] Tópico: ${TOPIC}${NC}"
echo "  Presiona Ctrl+C para detener"
echo "────────────────────────────────────────────────────────"

docker exec -it "$BROKER" kafka-console-consumer \
  --bootstrap-server "$BOOTSTRAP" \
  --topic "$TOPIC" \
  --from-beginning \
  --property print.key=false \
  --property print.value=true
