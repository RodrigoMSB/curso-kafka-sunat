#!/bin/bash
# Lista todos los connectors registrados en Kafka Connect.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${CYAN}[List Connectors]${NC}"
echo "────────────────────────────────────────────────────────"

curl -s http://localhost:8083/connectors | python3 -m json.tool 2>/dev/null || \
  curl -s http://localhost:8083/connectors
echo ""
