#!/bin/bash
# Crea el JDBC Source connector usando la config en infra/connect/jdbc-source-pedidos.json.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="${LAB_DIR}/infra/connect/jdbc-source-pedidos.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: $CONFIG_FILE no encontrado${NC}"
    exit 1
fi

echo -e "${CYAN}[Create Source Connector] novatech-source-pedidos${NC}"
echo "────────────────────────────────────────────────────────"

curl -s -X POST -H "Content-Type: application/json" \
  --data @"$CONFIG_FILE" \
  http://localhost:8083/connectors | python3 -m json.tool 2>/dev/null

echo ""
echo -e "${GREEN}  ✓ Connector enviado${NC}"
echo -e "${YELLOW}Verifica estado con:${NC} connect-cli/status-connector.sh novatech-source-pedidos"
