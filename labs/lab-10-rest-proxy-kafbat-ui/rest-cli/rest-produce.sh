#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
REST_URL="${REST_URL:-http://localhost:8082}"
TOPIC="${1:-novatech.lab10.pedidos}"
DEFAULT_VALUE='{"pedido":1,"cliente":"ACME","monto":1500}'
VALUE="${2:-$DEFAULT_VALUE}"
echo -e "${CYAN}[REST Produce] POST ${REST_URL}/topics/${TOPIC}${NC}"
curl -s -X POST \
  -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data "{\"records\":[{\"value\":${VALUE}}]}" \
  "${REST_URL}/topics/${TOPIC}"
echo ""
echo -e "${GREEN}✓ Mensaje enviado vía HTTP${NC}"
