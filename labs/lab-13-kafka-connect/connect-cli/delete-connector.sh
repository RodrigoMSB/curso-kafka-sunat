#!/bin/bash
# Elimina un connector de Kafka Connect.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

NOMBRE="${1:?Uso: $0 <nombre-connector>}"

echo -e "${YELLOW}[Delete Connector] $NOMBRE${NC}"

curl -s -X DELETE "http://localhost:8083/connectors/${NOMBRE}"
echo -e "${GREEN}  ✓ Connector $NOMBRE eliminado${NC}"
