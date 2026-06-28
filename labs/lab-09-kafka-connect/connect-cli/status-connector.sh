#!/bin/bash
# Muestra estado detallado de un connector y sus tasks.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

NOMBRE="${1:?Uso: $0 <nombre-connector>}"

echo -e "${CYAN}[Status Connector] $NOMBRE${NC}"
echo "────────────────────────────────────────────────────────"

curl -s "http://localhost:8083/connectors/${NOMBRE}/status" | python3 -m json.tool 2>/dev/null
