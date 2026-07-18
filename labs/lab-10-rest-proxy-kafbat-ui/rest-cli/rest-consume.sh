#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
REST_URL="${REST_URL:-http://localhost:8082}"
TOPIC="${1:-novatech.lab10.pedidos}"
GROUP="${2:-novatech-rest-group}"
INSTANCE="ci-$$"

echo -e "${CYAN}[REST Consume] Ciclo completo del consumer HTTP${NC}"

echo -e "${YELLOW}1. Crear instancia (${INSTANCE}) en grupo ${GROUP}...${NC}"
curl -s -X POST \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  --data "{\"name\":\"${INSTANCE}\",\"format\":\"json\",\"auto.offset.reset\":\"earliest\"}" \
  "${REST_URL}/consumers/${GROUP}"
echo ""

echo -e "${YELLOW}2. Suscribir al tópico ${TOPIC}...${NC}"
curl -s -X POST \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  --data "{\"topics\":[\"${TOPIC}\"]}" \
  "${REST_URL}/consumers/${GROUP}/instances/${INSTANCE}/subscription"

echo -e "${YELLOW}3. Primer poll (inicializa la suscripción, suele venir vacío)...${NC}"
curl -s -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
  "${REST_URL}/consumers/${GROUP}/instances/${INSTANCE}/records" > /dev/null
sleep 2

echo -e "${YELLOW}4. Segundo poll (trae los mensajes)...${NC}"
curl -s -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
  "${REST_URL}/consumers/${GROUP}/instances/${INSTANCE}/records"
echo ""

echo -e "${YELLOW}5. Borrar la instancia...${NC}"
curl -s -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" \
  "${REST_URL}/consumers/${GROUP}/instances/${INSTANCE}"
echo ""
echo -e "${GREEN}✓ Ciclo de consumo HTTP completado${NC}"
