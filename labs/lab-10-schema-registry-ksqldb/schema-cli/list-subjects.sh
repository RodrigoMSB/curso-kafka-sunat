#!/bin/bash
# Lista todos los subjects (schemas) registrados.
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${CYAN}[List Subjects]${NC}"
echo "────────────────────────────────────────────────────────"
curl -s http://localhost:8081/subjects | python3 -m json.tool 2>/dev/null
