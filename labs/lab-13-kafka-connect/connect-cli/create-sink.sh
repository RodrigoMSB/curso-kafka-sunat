#!/bin/bash
# Crea el JDBC Sink connector usando la config en infra/connect/jdbc-sink-procesados.json.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="${LAB_DIR}/infra/connect/jdbc-sink-procesados.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: $CONFIG_FILE no encontrado${NC}"
    exit 1
fi

echo -e "${CYAN}[Create Sink Connector] novatech-sink-procesados${NC}"
echo "────────────────────────────────────────────────────────"

curl -s -X POST -H "Content-Type: application/json" \
  --data @"$CONFIG_FILE" \
  http://localhost:8083/connectors | python3 -m json.tool 2>/dev/null

echo ""
echo -e "${GREEN}  ✓ Connector enviado${NC}"
echo -e "${YELLOW}Verifica estado con:${NC} connect-cli/status-connector.sh novatech-sink-procesados"
