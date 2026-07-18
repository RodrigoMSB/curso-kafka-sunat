#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
REST_URL="${REST_URL:-http://localhost:8082}"
echo -e "${CYAN}[REST] GET ${REST_URL}/topics${NC}"
curl -s "${REST_URL}/topics"
echo ""
